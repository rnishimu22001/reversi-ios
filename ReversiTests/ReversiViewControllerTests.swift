import XCTest
@testable import Reversi

class ReversiViewControllerTests: XCTestCase {
    
    var observation: [NSKeyValueObservation] = []
    
    override func tearDown() {
        observation = []
    }
   
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
    
    // MARK: Game Management
    
    func testNewGame() {
        // Given
        let mockRepository = MockGameRepository()
        let target = ViewController()
        let mockBoard = MockBoardView()
        target.boardView = mockBoard
        target.messageDiskView = DiskView(frame: .zero)
        target.messageLabel = UILabel(frame: .zero)
        target.playerControls = controls
        target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
        target.messageDiskView.layoutIfNeeded()
        target.messageDiskView.layoutIfNeeded()
        target.messageDiskSizeConstraint.isActive = true
        target.messageLabel = UILabel(frame: .zero)
        target.messageDiskSize = 5
        target.countLabels = [UILabel(frame: .zero), UILabel(frame: .zero)]
        target.gameRepository = mockRepository
        mockRepository.restored = Game(turn: .light, board: Board(), darkPlayer: .computer, lightPlayer: .manual)
        do {
            try target.restoreBoardView()
        } catch {
            fatalError()
        }
        // Then
        let resetExpectation = expectation(description: "Viewのリセットがされること")
        mockBoard.resetCompletion = { resetExpectation.fulfill() }
        // When
        target.newGame()
        // Then
        XCTAssertEqual(target.turn, .dark)
        target.playerControls.forEach {
            XCTAssertEqual($0.selectedSegmentIndex, Player.manual.rawValue)
        }
        
        wait(for: [resetExpectation], timeout: 0.01)
    }
    
    // MARK: Views
    
    func testUpdateCountLabels() {
        // Given
        let target = ViewController()
        let firstLabel = MockUILabel(frame: .zero)
        let lastLabel = MockUILabel(frame: .zero)
        target.countLabels = [firstLabel, lastLabel]
        
        let mockViewModel = MockReversiViewModel()
        mockViewModel.darkPlayerStatus.value = PlayerStatusDisplayData(playerType: .manual, diskCount: 1)
        mockViewModel.lightPlayerStatus.value = PlayerStatusDisplayData(playerType: .computer, diskCount: 2)
        target.viewModel = mockViewModel
        // Then
        let firstExpectation = expectation(description: "darkのプレイヤーのカウント更新")
        observation.append(firstLabel.observe(\.text) { _, change in
            XCTAssertEqual(firstLabel.textArgs.first, "1", "darkのプレイヤーのカウントが更新されること")
            XCTAssertEqual(firstLabel.textArgs.count, 1, "購読時の1回のみの更新")
            firstExpectation.fulfill()
        })
        let lastExpectation = expectation(description: "lightのプレイヤーのカウント更新")
        observation.append(lastLabel.observe(\.text) { _, change in
            XCTAssertEqual(lastLabel.textArgs.first, "2", "lightのプレイヤーのカウントが更新されること")
            XCTAssertEqual(lastLabel.textArgs.count, 1, "購読時の1回のみの更新")
            lastExpectation.fulfill()
        })
        // When
        target.sink()
        wait(for: [firstExpectation, lastExpectation], timeout: 1)
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
            
            // 範囲外のデータ
            Coordinates(x: 1, y: BoardView().height): Disk.light,
            Coordinates(x: BoardView().width, y: 1): Disk.light,
        ]
        mockBord.dummyDisks = dummyDisks
        var board = Board()
        do {
            try board.set(disk: .dark, at: Coordinates(x: 0, y: 0))
            try board.set(disk: .light, at: Coordinates(x: 1, y: board.height - 1))
            try board.set(disk: .light, at: Coordinates(x: board.width - 1, y: 2))
        } catch {
            fatalError()
        }
        
        let mockViewModel = MockReversiViewModel()
        mockViewModel.board = board
        target.viewModel = mockViewModel
        
        // When Then
        XCTAssertEqual(board.disks.filter { $0.value == .dark }.count,
                       target.countDisks(of: .dark),
                       "darkのみカウントされること")
        
        XCTAssertEqual(board.disks
            .filter { $0.value == .light }
            .count,
                       target.countDisks(of: .light),
                       "lightのみカウントされること")
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
                var board = Board()
                do {
                    try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
                    try board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
                } catch {
                    fatalError()
                }
                
                let mockViewModel = MockReversiViewModel()
                mockViewModel.board = board
                target.viewModel = mockViewModel
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
                var board = Board()
                do {
                    try board.set(disk: .dark, at: Coordinates(x: 1, y: 1))
                    try board.set(disk: .light, at: Coordinates(x: 2, y: 2))
                } catch {
                    fatalError()
                }
                
                let mockViewModel = MockReversiViewModel()
                mockViewModel.board = board
                target.viewModel = mockViewModel
                XCTAssertTrue(target.canPlaceDisk(.light, atX: 0, y: 0))
            }
            XCTContext.runActivity(named: "flipできない") { _ in
                // Given
                let target = ViewController()
                var board = Board()
                do {
                    try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
                    try board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
                } catch {
                    fatalError()
                }
                
                let mockViewModel = MockReversiViewModel()
                mockViewModel.board = board
                target.viewModel = mockViewModel
                XCTAssertFalse(target.canPlaceDisk(.light, atX: 0, y: 0))
            }
        }
    }
    
    func testValidMoves() {
        // Given
        let target = ViewController()
        var board = Board()
        do {
            try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
            try board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
        } catch {
            fatalError()
        }
        
        let mockViewModel = MockReversiViewModel()
        mockViewModel.board = board
        target.viewModel = mockViewModel
        XCTAssertTrue(target.validMoves(for: .light).contains(where: ({ $0.x == 3 && $0.y == 3 })), "範囲内")
        XCTAssertEqual(target.validMoves(for: .light).count, 1)
        XCTAssertEqual(target.validMoves(for: .dark).count, 1)
    }
    
    func testPlaceDisk() {
        XCTContext.runActivity(named: "盤上にセット可能な箇所がない") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            let mockViewModel = MockReversiViewModel()
            target.viewModel = mockViewModel
            let mockSpecifications = MockReversiSpecifications()
            target.specifications = mockSpecifications
            mockSpecifications.stubbedFlippedDiskCoordinatesByPlacingResult = []
            do {
                try target.placeDisk(.dark, atX: 0, y: 0) { _ in XCTFail("completionが呼ばれない") }
                XCTFail()
            } catch(let error) {
                if let placementError = error as? DiskPlacementError {
                    XCTAssertEqual(placementError.x, 0)
                    XCTAssertEqual(placementError.y, 0)
                    XCTAssertEqual(placementError.disk, .dark)
                } else {
                    XCTFail("指定のエラーではない場合")
                }
            }
            XCTAssertTrue(mockBord.setDiskArgs.isEmpty, "ディスクのセットが呼ばれないこと")
            XCTAssertTrue(mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.isEmpty, "ディスクのセットが呼ばれないこと")
        }
        XCTContext.runActivity(named: "盤上にセット可能な箇所がある") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            let mockViewModel = MockReversiViewModel()
            target.viewModel = mockViewModel
            target.playerControls = controls
            target.countLabels = [UILabel(frame: .zero), UILabel(frame: .zero)]
            let willSetDiskArgs = [
                SetDiskArgForMockView(disk: .dark, x: 0, y: 0, aniamted: true),
                SetDiskArgForMockView(disk: .dark, x: 1, y: 1, aniamted: true),
                SetDiskArgForMockView(disk: .dark, x: 2, y: 2, aniamted: true)
            ]
            let mockSpecifications = MockReversiSpecifications()
            target.specifications = mockSpecifications
            mockSpecifications.stubbedFlippedDiskCoordinatesByPlacingResult = [
                Coordinates(x: 1, y: 1),
                Coordinates(x: 2, y: 2)
            ]
            let completionExpectation = expectation(description: "plac diskのcompletionが実行されること")
            // When
            do {
                try target.placeDisk(.dark, atX: 0, y: 0, completion: { isFinished in
                    completionExpectation.fulfill()
                    XCTAssertTrue(isFinished)
                })
            } catch {
                XCTFail("成功する想定")
            }
            // Then
            XCTAssertEqual(mockBord.setDiskArgs, willSetDiskArgs, "指定された順番でディスクのセットが実行される")
            XCTAssertEqual(mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.count, willSetDiskArgs.count)
            mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.enumerated().forEach {
                XCTAssertEqual(willSetDiskArgs[$0.offset].disk, $0.element.disk, "指定された順番でディスクのセットが実行される")
                XCTAssertEqual(willSetDiskArgs[$0.offset].x, $0.element.x)
                XCTAssertEqual(willSetDiskArgs[$0.offset].y, $0.element.y)
            }
            XCTAssertNil(target.animationCanceller, "実行完了後にcancellerがnilに")
            wait(for: [completionExpectation], timeout: 0.01)
        }
        XCTContext.runActivity(named: "placeDisk実行中にキャンセルされた") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            let mockViewModel = MockReversiViewModel()
            target.viewModel = mockViewModel
            target.playerControls = controls
            target.countLabels = [UILabel(frame: .zero), UILabel(frame: .zero)]
            
            let mockSpecifications = MockReversiSpecifications()
            target.specifications = mockSpecifications
            mockSpecifications.stubbedFlippedDiskCoordinatesByPlacingResult = [
                Coordinates(x: 1, y: 1),
                Coordinates(x: 2, y: 2)
            ]
            // completionをキャプチャーして実行させない
            mockBord.shouldCaputreCompletion = true
            // When
            do {
                try target.placeDisk(.dark, atX: 0, y: 0, completion: {_ in XCTFail("cancel済みのためcompletionが実行されない") })
            } catch {
                XCTFail("成功する想定")
            }
            // キャンセルされた後のcompletionの実行を再現
            let canceler = Canceller(nil)
            canceler.cancel()
            target.animationCanceller = canceler
            mockBord.capturedCompletion?(true)
            // Then
            // animationCancelerがクロージャー内でキャプチャされるので、初回の1回目でキャンセルされず合計2回セットが呼ばれる
            let willSetDiskArgs = [
                SetDiskArgForMockView(disk: .dark, x: 0, y: 0, aniamted: true),
                SetDiskArgForMockView(disk: .dark, x: 1, y: 1, aniamted: true)
            ]
            XCTAssertEqual(willSetDiskArgs, mockBord.setDiskArgs, "cancel済みのためsetDiskが実行されない")
        }
        XCTContext.runActivity(named: "アニメーションが完了できなかった") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            let mockViewModel = MockReversiViewModel()
            target.viewModel = mockViewModel
            target.playerControls = controls
            target.countLabels = [UILabel(frame: .zero), UILabel(frame: .zero)]
            
            let mockSpecifications = MockReversiSpecifications()
            target.specifications = mockSpecifications
            mockSpecifications.stubbedFlippedDiskCoordinatesByPlacingResult = [
                Coordinates(x: 1, y: 1),
                Coordinates(x: 2, y: 2)
            ]
            // completionをキャプチャーして実行させない
            mockBord.shouldCaputreCompletion = true
            let completionExpectation = expectation(description: "setDisk完了後にcompletionが実行される")
            // When
            do {
                try target.placeDisk(.dark, atX: 0, y: 0, completion: { isFinished in
                    completionExpectation.fulfill()
                    XCTAssertFalse(isFinished)
                })
            } catch {
                XCTFail("成功する想定")
            }
            // アニメーションが失敗すること再現
            mockBord.capturedCompletion?(false)
            // Then
            let willSetDiskArgs = [
                SetDiskArgForMockView(disk: .dark, x: 0, y: 0, aniamted: true),
                // アニメーションに失敗した場合はアニメーションなしで更新が入る
                SetDiskArgForMockView(disk: .dark, x: 0, y: 0, aniamted: false),
                SetDiskArgForMockView(disk: .dark, x: 1, y: 1, aniamted: false),
                SetDiskArgForMockView(disk: .dark, x: 2, y: 2, aniamted: false),
            ]
            XCTAssertEqual(willSetDiskArgs, mockBord.setDiskArgs, "アニメーション有りのsetのあとアニメーション無しのsetが入る")
            let animated = willSetDiskArgs.filter { $0.aniamted == true }
            let nonAnimated = willSetDiskArgs.filter { $0.aniamted == false }
                
            XCTAssertEqual(mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.count,
                           animated.count)
            XCTAssertEqual(mockViewModel.invokedSetDiskDiskAtMultiCoordinatesParametersList.count, 1, "複数セットが呼ばれるのは一回だけ")
            XCTAssertEqual(mockViewModel.invokedSetDiskDiskAtMultiCoordinatesParametersList.first!.coodinates.count,
                           nonAnimated.filter { $0.aniamted == false }.count,
                           "複数の座標が一度にセットされる")
            mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.enumerated().forEach {
                XCTAssertEqual(animated[$0.offset].disk, $0.element.disk, "指定された順番でディスクのセットが実行される")
                XCTAssertEqual(animated[$0.offset].x, $0.element.x)
                XCTAssertEqual(animated[$0.offset].y, $0.element.y)
            }
            XCTAssertEqual(mockViewModel.invokedSetDiskDiskAtMultiCoordinatesParametersList.first!.disk, .dark)
            mockViewModel.invokedSetDiskDiskAtMultiCoordinatesParametersList.first!.coodinates.enumerated().forEach {
                XCTAssertEqual(nonAnimated[$0.offset].x, $0.element.x, "指定された順番でディスクのセットが実行される")
                XCTAssertEqual(nonAnimated[$0.offset].y, $0.element.y)
            }
            wait(for: [completionExpectation], timeout: 0.01)
        }
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
        
        let mockViewModel = MockReversiViewModel()
        mockViewModel.board = board
        target.viewModel = mockViewModel
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
