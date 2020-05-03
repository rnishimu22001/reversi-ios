import XCTest
@testable import Reversi

class ReversiViewControllerTests: XCTestCase {
   
    // MARK: Mock views
    var controls: [UISegmentedControl] {
        Disk.allCases.enumerated().map {
            let control = UISegmentedControl(items: nil)
            control.insertSegment(withTitle: "Manual", at: 0, animated: false)
            control.insertSegment(withTitle: "Computer", at: 1, animated: false)
            control.selectedSegmentIndex = $0.offset
            return control
        }
    }
    
    // MARK: Views
    
    func testUpdateCountLabels() {
        let target = ViewController()
        let firstLabel = UILabel(frame: .zero)
        let lastLabel = UILabel(frame: .zero)
        let mockBord = MockBoardView(frame: .zero)
        target.countLabels = [firstLabel, lastLabel]
        target.boardView = mockBord
        let dummyDisks = [
            Coordinates(x: 0, y: 0): Disk.dark,
            Coordinates(x: 1, y: BoardView().height - 1): Disk.light,
            Coordinates(x: BoardView().width - 1, y: 2): Disk.light,
        ]
        mockBord.dummyDisks = dummyDisks
        // When
        target.updateCountLabels()
        // Then
        XCTAssertEqual(firstLabel.text, "1", "darkのプレイヤーのカウントが更新されること")
        XCTAssertEqual(lastLabel.text, "2", "lightのプレイヤーのカウントが更新されること")
    }
    
    func testUpdateMessageView() {
        let diskSize: CGFloat = 5
        XCTContext.runActivity(named: "ゲーム中") { _ in
            // Given
            let mockRepository = MockGameRepository()
            let target = ViewController()
            target.boardView = BoardView(frame: .zero)
            target.messageDiskView = DiskView(frame: .zero)
            target.messageLabel = UILabel(frame: .zero)
            target.playerControls = controls
            target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
            target.messageDiskView.layoutIfNeeded()
            target.messageDiskView.layoutIfNeeded()
            target.messageDiskSizeConstraint.isActive = true
            target.messageLabel = UILabel(frame: .zero)
            target.messageDiskSize = diskSize
            target.gameRepository = mockRepository
            mockRepository.restored = Game(turn: .light, board: Board(), darkPlayer: .computer, lightPlayer: .manual)
            do {
                try target.restoreBoardView()
            } catch {
                fatalError()
            }
            // When
            target.updateMessageViews()
            // Then
            XCTAssertEqual(target.messageDiskView.disk, .light)
            XCTAssertEqual(target.messageLabel.text, "'s turn")
            XCTAssertEqual(target.messageDiskSizeConstraint.constant, diskSize)
        }
        XCTContext.runActivity(named: "ゲーム終了") { _ in
            XCTContext.runActivity(named: "一方の勝ち") { _ in
                // Given
                let mockRepository = MockGameRepository()
                let target = ViewController()
                target.boardView = BoardView(frame: .zero)
                target.messageDiskView = DiskView(frame: .zero)
                target.messageLabel = UILabel(frame: .zero)
                target.playerControls = controls
                target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
                target.messageDiskView.layoutIfNeeded()
                target.messageDiskView.layoutIfNeeded()
                target.messageDiskSizeConstraint.isActive = true
                target.messageLabel = UILabel(frame: .zero)
                target.messageDiskSize = diskSize
                target.gameRepository = mockRepository
                var board = Board()
                // dark側がディスクが多い状態
                do {
                    try board.set(disk: .dark, at: Coordinates(x: 0, y: 0))
                } catch {
                    fatalError()
                }
                // turnがnilでゲーム終了
                mockRepository.restored = Game(turn: nil, board: board, darkPlayer: .computer, lightPlayer: .manual)
                do {
                    try target.restoreBoardView()
                } catch {
                    fatalError()
                }
                // When
                target.updateMessageViews()
                // Then
                XCTAssertEqual(target.messageDiskView.disk, .dark)
                XCTAssertEqual(target.messageLabel.text, " won")
                XCTAssertEqual(target.messageDiskSizeConstraint.constant, diskSize)
            }
            XCTContext.runActivity(named: "引き分け") { _ in
                let mockRepository = MockGameRepository()
                let target = ViewController()
                target.boardView = BoardView(frame: .zero)
                target.messageDiskView = DiskView(frame: .zero)
                target.messageLabel = UILabel(frame: .zero)
                target.playerControls = controls
                target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
                target.messageDiskView.layoutIfNeeded()
                target.messageDiskView.layoutIfNeeded()
                target.messageDiskSizeConstraint.isActive = true
                target.messageLabel = UILabel(frame: .zero)
                target.messageDiskSize = diskSize
                target.gameRepository = mockRepository
                // turnがnilでゲーム終了
                mockRepository.restored = Game(turn: nil, board: Board(), darkPlayer: .computer, lightPlayer: .manual)
                do {
                    try target.restoreBoardView()
                } catch {
                    fatalError()
                }
                // When
                target.updateMessageViews()
                // Then
                XCTAssertEqual(target.messageDiskView.disk, .dark, "引き分けだがdisk viewがひょうじされたまま")
                XCTAssertEqual(target.messageDiskSizeConstraint.constant, 0, "messageDiskSizeを0にしてdiskViewを隠す")
                XCTAssertEqual(target.messageLabel.text, "Tied")
            }
        }
    }
    
    // MARK: - Reversi logics
    
    func testCountDisks() {
        // Given
        let target = ViewController()
        let mockBord = MockBoardView(frame: .zero)
        target.boardView = mockBord
        let dummyDisks = [
            Coordinates(x: 0, y: 0): Disk.dark,
            Coordinates(x: 1, y: BoardView().height - 1): Disk.light,
            Coordinates(x: BoardView().width - 1, y: 2): Disk.light,
            // 範囲外のデータ
            Coordinates(x: 1, y: BoardView().height): Disk.light,
            Coordinates(x: BoardView().width, y: 1): Disk.light,
        ]
        mockBord.dummyDisks = dummyDisks
        
        // When Then
        XCTAssertEqual(dummyDisks.filter { $0.value == .dark }.count,
                       target.countDisks(of: .dark),
                       "darkのみカウントされること")
        
        XCTAssertEqual(dummyDisks
            .filter { $0.value == .light }
            .filter { BoardView().xRange.contains($0.key.x) }
            .filter { BoardView().yRange.contains($0.key.y) }
            .count,
                       target.countDisks(of: .light),
                       "範囲外のデータはカウントに含まれないこと")
    }
    
    func testCanPlaceDisk() {
        XCTContext.runActivity(named: "すでにDiskが置かれている") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            let path = Coordinates(x: 0, y: 0)
            mockBord.dummyDisks = [path: .light]
            XCTAssertFalse(target.canPlaceDisk(.dark, atX: path.x, y: path.y))
        }
        XCTContext.runActivity(named: "dark") { _ in
            XCTContext.runActivity(named: "flipできない") { _ in
                // Given
                let target = ViewController()
                let mockBord = MockBoardView(frame: .zero)
                target.boardView = mockBord
                mockBord.dummyDisks = [
                    Coordinates(x: 1, y: 1): .light,
                    Coordinates(x: 2, y: 2): .dark
                ]
                XCTAssertTrue(target.canPlaceDisk(.dark, atX: 0, y: 0))
            }
            XCTContext.runActivity(named: "flipできる") { _ in
                // Given
                let target = ViewController()
                let mockBord = MockBoardView(frame: .zero)
                target.boardView = mockBord
                mockBord.dummyDisks = [
                    Coordinates(x: 1, y: 1): .dark,
                    Coordinates(x: 2, y: 2): .dark
                ]
                XCTAssertFalse(target.canPlaceDisk(.dark, atX: 0, y: 0))
            }
        }
        XCTContext.runActivity(named: "light") { _ in
            XCTContext.runActivity(named: "flipできる") { _ in
                // Given
                let target = ViewController()
                let mockBord = MockBoardView(frame: .zero)
                target.boardView = mockBord
                mockBord.dummyDisks = [
                    Coordinates(x: 1, y: 1): .dark,
                    Coordinates(x: 2, y: 2): .light
                ]
                XCTAssertTrue(target.canPlaceDisk(.light, atX: 0, y: 0))
            }
            XCTContext.runActivity(named: "flipできない") { _ in
                // Given
                let target = ViewController()
                let mockBord = MockBoardView(frame: .zero)
                target.boardView = mockBord
                mockBord.dummyDisks = [
                    Coordinates(x: 1, y: 1): .light,
                    Coordinates(x: 2, y: 2): .dark
                ]
                XCTAssertFalse(target.canPlaceDisk(.light, atX: 0, y: 0))
            }
        }
    }
    
    func testValidMoves() {
        // Given
        let target = ViewController()
        let mockBord = MockBoardView(frame: .zero)
        target.boardView = mockBord
        mockBord.dummyDisks = [
            Coordinates(x: 1, y: 1): .light,
            Coordinates(x: 2, y: 2): .dark,
            // 範囲外、盤外に置かれたコマ
            Coordinates(x: mockBord.width, y: mockBord.height): .light,
            Coordinates(x: mockBord.width + 1, y: mockBord.height + 1): .dark,
        ]
        XCTAssertTrue(target.validMoves(for: .light).contains(where: ({ $0.x == 3 && $0.y == 3 })), "範囲内")
        XCTAssertFalse(target.validMoves(for: .dark).contains(where: ({ ($0.x == mockBord.width - 1) && ($0.y == mockBord.height - 1) })), "範囲外")
        XCTAssertEqual(target.validMoves(for: .light).count, 1)
        XCTAssertEqual(target.validMoves(for: .dark).count, 1)
    }
    
    // MARK: - Save and Load
    
    func testSaveGame() {
        // Given
        let boardView = BoardView(frame: .zero)
        boardView.setDisk(.dark, atX: 2, y: 3, animated: false)
        boardView.setDisk(.dark, atX: 3, y: 3, animated: false)
        boardView.setDisk(.dark, atX: 4, y: 3, animated: false)
        boardView.setDisk(.dark, atX: 3, y: 4, animated: false)
        boardView.setDisk(.light, atX: 4, y: 4, animated: false)
        let target = ViewController()
        target.boardView = boardView
        let controls = self.controls
        target.playerControls = controls
        let repository = MockGameRepository()
        target.gameRepository = repository
        // When
        do {
            try target.saveGame()
        } catch {
            fatalError()
        }
        // Then
        XCTAssertEqual(repository.saved!.darkPlayer, .manual)
        XCTAssertEqual(repository.saved!.lightPlayer, .computer)
        XCTAssertEqual(repository.saved!.turn, .dark)
        XCTAssertEqual(repository.saved!.board.disk(atX: 2, y: 3), .dark)
        XCTAssertEqual(repository.saved!.board.disk(atX: 3, y: 3), .dark)
        XCTAssertEqual(repository.saved!.board.disk(atX: 4, y: 3), .dark)
        XCTAssertEqual(repository.saved!.board.disk(atX: 3, y: 4), .dark)
        XCTAssertEqual(repository.saved!.board.disk(atX: 4, y: 4), .light)
    }
    
    func testLoadGame() {
        XCTContext.runActivity(named: "正常データ") { _ in
            
            // Given
            let boardView = BoardView(frame: .zero)
            let target = ViewController()
            target.boardView = boardView
            let controls = self.controls
            controls.forEach {
                $0.selectedSegmentIndex = 0
                XCTAssertEqual($0.selectedSegmentIndex, 0, "テストデータから1に切り替わることをテストするためにここで0をセットする")
            }
            target.playerControls = controls
            let repository = MockGameRepository()
            target.gameRepository = repository
            var board = Board()
            do {
                try board.set(disk: .dark, at: Coordinates(x: 2, y: 3))
                try board.set(disk: .dark, at: Coordinates(x: 3, y: 3))
                try board.set(disk: .dark, at: Coordinates(x: 4, y: 3))
                try board.set(disk: .dark, at: Coordinates(x: 3, y: 4))
                try board.set(disk: .light, at: Coordinates(x: 4, y: 4))
            } catch {
                fatalError()
            }
            repository.restored = Game(turn: .dark, board: board, darkPlayer: .manual, lightPlayer: .computer)
            
            // When
            do {
                try target.restoreBoardView()
            } catch {
                fatalError()
            }
            // Then
            (1...(boardView.height * boardView.width)).forEach {
                let x = $0 / boardView.height
                let y = $0 % boardView.height
                switch (x, y) {
                case (2, 3), (3, 3), (4, 3), (3, 4):
                    XCTAssertEqual(boardView.diskAt(x: x, y: y), .dark, "x: \(x),y: \(y)")
                case (4, 4):
                    XCTAssertEqual(boardView.diskAt(x: x, y: y), .light, "x: \(x),y: \(y)")
                default:
                    XCTAssertNil(boardView.diskAt(x: x, y: y))
                }
            }
            XCTAssertEqual(target.turn, .dark)
            XCTAssertEqual(controls[0].selectedSegmentIndex, 0, "x01なので初手のプレイヤーは0")
            XCTAssertEqual(controls[1].selectedSegmentIndex, 1, "x01なので後手のプレイヤーは1")
        }
    }
}
