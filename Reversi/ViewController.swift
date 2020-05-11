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
    var turn: Disk? { viewModel.turn }
    
    lazy var navigator: Navigator = NavigatorImplementation(viewController: self)
    
    var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }
    
    private(set) var playerCancellers: [Disk: Canceller] = [:]
    
    private var cancellables: Set<AnyCancellable> = []
    
    /// リファクタリング用、後ほど削除
    var gameRepository: GameRepository = GameRepositoryImplementation()
    var specifications: ReversiSpecifications = ReversiSpecificationsImplementation()
    var viewModel: ReversiViewModel = ReversiViewModelImplementation()
    lazy var manager: GameManager = GameManagerImplementation(specifications: specifications)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant
        sinkPlayerStatus()
        sinkMessage()
        sinkBoard()
        do {
            try loadGame()
        } catch _ {
            newGame()
        }
    }
        
    func sinkBoard() {
        viewModel
            .boardStatus
            .sink { [weak self] type in
            // mainスケジューラでsubscribeした場合に即時イベント発行がきても受け取れない
                DispatchQueue.main.async {
                    switch type {
                    case .withAnimation(let disks):
                        guard let first = disks.first else { return }
                        self?.animateSettingDisks(at: disks.map { $0.coordinates }, to: first.side) { _ in
                            self?.nextTurn()
                        }
                    case .withoutAnimation(let disks):
                        disks.forEach {
                            self?.boardView.setDisk($0.side, at: $0.coordinates, animated: false)
                        }
                    }
                }
        }
        .store(in: &cancellables)
    }
    
    func sinkMessage() {
        viewModel
            .message
            .subscribe(on: DispatchQueue.main)
            .sink { [weak self] data in self?.updateMessageViews(with: data) }
            .store(in: &cancellables)
    }
    
    func sinkPlayerStatus() {
        viewModel
            .darkPlayerStatus
            .subscribe(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.playerControls[Disk.dark.index].selectedSegmentIndex = data.playerType.rawValue
                self.countLabels[Disk.dark.index].text = data.diskCount.description
                
        }
        .store(in: &cancellables)
        
        viewModel
            .lightPlayerStatus
            .subscribe(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.playerControls[Disk.light.index].selectedSegmentIndex = data.playerType.rawValue
                self.countLabels[Disk.light.index].text = data.diskCount.description
        }.store(in: &cancellables)
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayerIfNeeded()
    }
    
    var board: Board { viewModel.board }
}

// MARK: Reversi logics

extension ViewController {
    
    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        specifications.validMoves(for: side, on: board).map {
            return (x: $0.x, y: $0.y)
        }
    }

    func placeDisk(_ disk: Disk, atX x: Int, y: Int) throws {
        try viewModel.place(disk: disk, at: Coordinates(x: x, y: y))
    }
}

// MARK: animation
extension ViewController {
    
    func animateSettingDisks(at coordinates: [Coordinates], to disk: Disk, completion: ((Bool) -> Void)? = nil) {
        let cleanUp: () -> Void = { [weak self] in
            self?.animationCanceller = nil
        }
        animationCanceller = CancellerImplementation(cleanUp)
        animateSettingDisks(at: coordinates.map { ($0.x, $0.y) }, to: disk) { [weak self] isFinished in
            guard let self = self else { return }
            guard let canceller = self.animationCanceller else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            completion?(isFinished)
            try? self.saveGame()
            self.viewModel.updateDiskCount()
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
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                // 更新に失敗した場合は残りの全てをアニメーションなしで更新
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
        viewModel.reset()
        boardView.reset()
        try? saveGame()
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayerIfNeeded() {
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
        viewModel.nextTurn()
        guard let turn = self.turn else { return }
        // diskを置ける場所が無いことを確認
        guard validMoves(for: turn).isEmpty else {
            // 置ける場合はプレイヤーの行動を待つ
            waitForPlayerIfNeeded()
            return
        }
        
        // おける場所がなければAlert表示
        let alertController = UIAlertController(
            title: "Pass",
            message: "Cannot place a disk.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
            // 確認後スキップ
            self?.nextTurn()
        })
        navigator.present(alertController, animated: true, completion: nil)
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let turn = self.turn else { preconditionFailure() }

        playerActivityIndicators[turn.index].startAnimating()
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playerActivityIndicators[turn.index].stopAnimating()
            }
            self.playerCancellers[turn] = nil
        }
        let canceller = CancellerImplementation(cleanUp)
        manager.playTurnOfComputer(side: turn, on: board) { [weak self] coordinates in
            guard let coordinates = coordinates,
                let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            try? self.placeDisk(turn, atX: coordinates.x, y: coordinates.y)
        }
        playerCancellers[turn] = canceller
    }
}

// MARK: Views

extension ViewController {
    
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
            self.manager.canceleAllPlaying()
            
            self.newGame()
            self.waitForPlayerIfNeeded()
        })
        
        navigator.present(alertController, animated: true, completion: nil)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        viewModel.changePlayer(on: side)
        try? saveGame()
        manager.cancelPlaying(on: side)
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
        try? placeDisk(turn, atX: x, y: y)
    }
}

// MARK: Save and Load

extension ViewController {
    
    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame() throws {
        try gameRepository.save(game: viewModel.game)
    }
    
    func loadGame() throws {
        let game = try gameRepository.restore()
        viewModel.restore(from: game)
    }
}

struct ViewSettingError: Error {
    let message: String
}
