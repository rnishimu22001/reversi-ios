import UIKit
import Combine

final class ViewController: UIViewController {
    @IBOutlet var boardView: BoardView!
    
    @IBOutlet var messageDiskView: DiskView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    var messageDiskSize: CGFloat!
    
    @IBOutlet var playerControls: [UISegmentedControl]!
    @IBOutlet var countLabels: [UILabel]!
    @IBOutlet var playerActivityIndicators: [UIActivityIndicatorView]!
    
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    private(set) var turn: Disk? = .dark
    
    var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }
    
    private var playerCancellers: [Disk: Canceller] = [:]
    
    private var cancellables: [AnyCancellable] = []
    
    /// リファクタリング用、後ほど削除
    var gameRepository: GameRepository = GameRepositoryImplementation()
    var specifications: ReversiSpecifications = ReversiSpecificationsImplementation()
    var viewModel: ReversiViewModel = ReversiViewModelImplementation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant
        
        do {
            try loadGame()
        } catch _ {
            newGame()
        }
        sink()
    }
    
    func sink() {
    
        cancellables.append(viewModel.darkPlayerStatus.subscribe(on: DispatchQueue.main).sink { [weak self] data in
            // プレイヤータイプのつなぎ込みもしておくこと
            guard let self = self else { return }
            self.playerControls[Disk.dark.index].selectedSegmentIndex = data.playerType.rawValue
            self.countLabels[Disk.dark.index].text = data.diskCount.description
        })
        cancellables.append(viewModel.lightPlayerStatus.subscribe(on: DispatchQueue.main).sink { [weak self] data in
            // プレイヤータイプのつなぎ込みもしておくこと
            guard let self = self else { return }
            self.playerControls[Disk.light.index].selectedSegmentIndex = data.playerType.rawValue
            self.countLabels[Disk.light.index].text = data.diskCount.description
        })
        cancellables.append(viewModel.message.subscribe(on: DispatchQueue.main).sink { [weak self] data in
            self?.updateMessageViews(with: data)
        })
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }
    
    var board: Board { viewModel.board }
}

// MARK: Reversi logics

extension ViewController {
    
    private func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
        return specifications
            .flippedDiskCoordinatesByPlacing(disk: disk, on: board, at: Coordinates(x: x, y: y))
            .map { ($0.x, $0.y) }
    }
    
    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        specifications.canPlaceDisk(disk, on: board, at: Coordinates(x: x, y: y))
    }
    
    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        specifications.validMoves(for: side, on: board).map {
            return (x: $0.x, y: $0.y)
        }
    }

    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        
        let cleanUp: () -> Void = { [weak self] in
            self?.animationCanceller = nil
        }
        animationCanceller = Canceller(cleanUp)
        animateSettingDisks(at: [(x, y)] + diskCoordinates, to: disk) { [weak self] isFinished in
            guard let self = self else { return }
            guard let canceller = self.animationCanceller else { return }
            if canceller.isCancelled { return }
            cleanUp()

            completion?(isFinished)
            try? self.saveGame()
            self.updateCountLabels()
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }
        // アニメーション中にリセットされるとクラッシュする
        let animationCanceller = self.animationCanceller!
        viewModel.set(disk: disk, at: Coordinates(x: x, y: y))
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                // 更新に失敗した場合は残りの全てをアニメーションなしで更新
                self.viewModel.set(disk: disk, at: coordinates.map { Coordinates(x: $0.0, y: $0.1) } )
                for (x, y) in coordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() {
        viewModel.restore(from: Game(turn: .dark, board: specifications.initalState(from: board), darkPlayer: .manual, lightPlayer: .manual))
        boardView.reset()
        turn = .dark
        
        for playerControl in playerControls {
            playerControl.selectedSegmentIndex = Player.manual.rawValue
        }

        updateMessageViews()
        updateCountLabels()
        
        try? saveGame()
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = self.turn else { return }
        switch Player(rawValue: playerControls[turn.index].selectedSegmentIndex)! {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard var turn = self.turn else { return }

        turn.flip()
        viewModel.nextTurn()
        
        if validMoves(for: turn).isEmpty {
            if validMoves(for: turn.flipped).isEmpty {
                self.turn = nil
                updateMessageViews()
            } else {
                self.turn = turn
                updateMessageViews()
                
                let alertController = UIAlertController(
                    title: "Pass",
                    message: "Cannot place a disk.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                    self?.nextTurn()
                })
                present(alertController, animated: true)
            }
        } else {
            self.turn = turn
            updateMessageViews()
            waitForPlayer()
        }
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let turn = self.turn else { preconditionFailure() }
        let (x, y) = validMoves(for: turn).randomElement()!

        playerActivityIndicators[turn.index].startAnimating()
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.playerActivityIndicators[turn.index].stopAnimating()
            self.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(turn, atX: x, y: y) { [weak self] _ in
                self?.nextTurn()
            }
        }
        
        playerCancellers[turn] = canceller
    }
}

// MARK: Views

extension ViewController {
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        viewModel.updateDiskCount()
    }
    
    func updateMessageViews() {
        viewModel.updateMessage()
    }
    
    /// DisplayDataをもとにメッセージを表示します。
    func updateMessageViews(with displayData: MessageDisplayData) {
        switch displayData.displayedDisk {
        case .some(let turn):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = turn
        case .none:
            messageDiskSizeConstraint.constant = 0
        }
        messageLabel.text = displayData.message
    }
}

// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.animationCanceller?.cancel()
            self.animationCanceller = nil
            
            for side in Disk.allCases {
                self.playerCancellers[side]?.cancel()
                self.playerCancellers.removeValue(forKey: side)
            }
            
            self.newGame()
            self.waitForPlayer()
        })
        present(alertController, animated: true)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        
        try? saveGame()
        
        if let canceller = playerCancellers[side] {
            canceller.cancel()
        }
        
        if !isAnimating, side == turn, case .computer = Player(rawValue: sender.selectedSegmentIndex)! {
            playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let turn = turn else { return }
        if isAnimating { return }
        guard case .manual = Player(rawValue: playerControls[turn.index].selectedSegmentIndex)! else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, atX: x, y: y) { [weak self] _ in
            self?.nextTurn()
        }
    }
}

// MARK: Save and Load

extension ViewController {
    var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    
    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame() throws {
        var game = Game(turn: turn, board: Board(), darkPlayer: .manual, lightPlayer: .manual)
        for side in Disk.allCases {
            guard let player = Player(rawValue: playerControls[side.index].selectedSegmentIndex) else {
                throw FileIOError.read(path: path, cause: nil)
            }
            switch side {
            case .light:
                game.lightPlayer = player
            case .dark:
                game.darkPlayer = player
            }
        }
        
        game.board = self.board
        
        try gameRepository.save(game: game)
    }
    
    /// ゲームの状態をファイルから読み込み、復元します。
    func restoreBoardView() throws {
        let game = try gameRepository.restore()

        turn = game.turn
        viewModel.restore(from: game)
        game.board.disks.forEach {
            boardView.setDisk($0.value, atX: $0.key.x, y: $0.key.y, animated: false)
        }
    }
    
    func loadGame() throws {
        try restoreBoardView()
        updateMessageViews()
        updateCountLabels()
    }
}

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?
    
    init(_ body: (() -> Void)?) {
        self.body = body
    }
    
    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}

