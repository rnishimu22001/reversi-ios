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
    
    var indicators: [UIActivityIndicatorView] {
        return .init()
    }
    
    // MARK: Game Management
    
    func testNextTurn() {
        XCTContext.runActivity(named: "現在のターンがManualのプレイヤー、次がcomputerの場合") { _ in
            // Given
            let viewModel = MockReversiViewModel()
            let specifications = MockReversiSpecifications()
            let darkIndicator = MockUIIndicatorView()
            let lightIndicator = MockUIIndicatorView()
            let repository = MockGameRepository()
            let target = ViewController()
            target.boardView = MockBoardView()
            target.playerActivityIndicators = []
            target.playerActivityIndicators.append(darkIndicator)
            target.playerActivityIndicators.append(lightIndicator)
            target.specifications = specifications
            target.viewModel = viewModel
            target.gameRepository = repository
            target.playerControls = controls
            let validMoveResult = Coordinates(x: 0, y: 0)
            specifications.stubbedValidMovesResult = [validMoveResult]
            specifications.stubbedFlippedDiskCoordinatesByPlacingResult = [Coordinates(x: 1, y: 1)]
            // まだゲームが終わっていないことを設定
            specifications.isEndOfGame = false
            XCTAssertEqual(target.turn, .dark, "初期値の確認")
            
            // When
            target.nextTurn()
            // Then
            XCTAssertEqual(viewModel.nextTurnsInvokeCount, 1, "darkから手番が移る一回だけ呼ばれる")
            XCTAssertEqual(target.turn, .light, "ターンが切り替わったので手番がlightに移る")
            XCTAssertEqual(darkIndicator.startAnimatingCount, 0, "darkはComputerではない")
            XCTAssertEqual(lightIndicator.startAnimatingCount, 1, "lightはcomputerなのでlight側のindicatorがstart")
            XCTAssertNotNil(target.playerCancellers[.light],  "手番のプレイヤーはキャンセラーが設定される")
            XCTAssertNil(target.playerCancellers[.dark], "手番でない側はキャンセラーが設定されない")
            XCTAssertEqual(viewModel.updateMessageInvokedCount, 1)
        }
        XCTContext.runActivity(named: "darkとlight両方置ける場所がなくなった場合") { _ in
            // Given
            let viewModel = MockReversiViewModel()
            let specifications = MockReversiSpecifications()
            let darkIndicator = MockUIIndicatorView()
            let lightIndicator = MockUIIndicatorView()
            let repository = MockGameRepository()
            let target = ViewController()
            target.boardView = MockBoardView()
            target.playerActivityIndicators = []
            target.playerActivityIndicators.append(darkIndicator)
            target.playerActivityIndicators.append(lightIndicator)
            target.specifications = specifications
            target.viewModel = viewModel
            target.gameRepository = repository
            target.playerControls = controls
            specifications.stubbedValidMovesResult = []
            specifications.stubbedFlippedDiskCoordinatesByPlacingResult = []
            // 互いにおける場所がなくなった場合を設定
            specifications.isEndOfGame = true
            XCTAssertEqual(target.turn, .dark, "初期値の確認")
            
            // When
            target.nextTurn()
            // Then
            XCTAssertEqual(viewModel.updateMessageInvokedCount, 1)
            XCTAssertEqual(viewModel.nextTurnsInvokeCount, 1, "darkから手番が移る一回だけ呼ばれる")
            XCTAssertNil(target.turn, "決着がついたのでnilになる")
            XCTAssertEqual(darkIndicator.startAnimatingCount, 0, "darkはComputerではない")
            XCTAssertEqual(lightIndicator.startAnimatingCount, 0, "決着がついたので呼び出されない")
            XCTAssertNil(target.playerCancellers[.light],  "決着がついたので設定されない")
            XCTAssertNil(target.playerCancellers[.dark], "手番でない側はキャンセラーが設定されない")
        }
        XCTContext.runActivity(named: "dark側だけ置ける場所がなくなった場合") { _ in
            // Given
            let viewModel = MockReversiViewModel()
            let specifications = MockReversiSpecifications()
            let darkIndicator = MockUIIndicatorView()
            let lightIndicator = MockUIIndicatorView()
            let repository = MockGameRepository()
            let target = ViewController()
            let navigation = SpyNavigator()
            target.navigator = navigation
            target.boardView = MockBoardView()
            target.playerActivityIndicators = []
            target.playerActivityIndicators.append(darkIndicator)
            target.playerActivityIndicators.append(lightIndicator)
            target.specifications = specifications
            target.viewModel = viewModel
            target.gameRepository = repository
            target.playerControls = controls
            specifications.stubbedFlippedDiskCoordinatesByPlacingResult = []
            XCTAssertEqual(target.turn, .dark, "初期値の確認")
            // When
            specifications.validMoveCompletion = { side, coordinates in
                switch side {
                case .dark:
                    return [.init(x: 0, y: 0)]
                case .light:
                    return []
                }
            }
            // When
            target.nextTurn()
            // Then
            XCTAssertEqual(viewModel.updateMessageInvokedCount, 1)
            XCTAssertEqual(viewModel.nextTurnsInvokeCount, 1, "darkから手番が移る一回だけ呼ばれる")
            XCTAssertEqual(target.turn, .light, "次のプレイヤーに手番が移る")
            XCTAssertEqual(darkIndicator.startAnimatingCount, 0, "darkはComputerではない")
            XCTAssertEqual(lightIndicator.startAnimatingCount, 0, "lightは手番を飛ばされたのでIndicatorがStartしない")
            XCTAssertNil(target.playerCancellers[.light],  "lightは手番を飛ばされたのでキャンセラーが設定されない")
            XCTAssertNil(target.playerCancellers[.dark], "手番でない側はキャンセラーが設定されない")
            XCTAssertEqual(navigation.presentArgs.count, 1, "Alertの表示回数は一回だけ")
            guard let alert = navigation.presentArgs.first?.0 as? UIAlertController else {
                XCTFail("想定していないcontrollerが表示されています")
                return
            }
            XCTAssertEqual(alert.message, "Cannot place a disk.")
            XCTAssertEqual(alert.title, "Pass")
            XCTAssertEqual(alert.actions.count, 1)
            XCTAssertEqual(alert.actions.first?.title, "Dismiss")
        }
    }
    
    func testPlayTurnOfComputer() {
        XCTContext.runActivity(named: "正常に置き換えが実行される場合") { _ in
            // Given
            let viewModel = MockReversiViewModel()
            let specifications = MockReversiSpecifications()
            let darkIndicator = MockUIIndicatorView()
            let lightIndicator = MockUIIndicatorView()
            let repository = MockGameRepository()
            let target = ViewController()
            target.boardView = MockBoardView()
            target.playerActivityIndicators = []
            target.playerActivityIndicators.append(darkIndicator)
            target.playerActivityIndicators.append(lightIndicator)
            target.specifications = specifications
            target.viewModel = viewModel
            target.gameRepository = repository
            target.playerControls = controls
            let validMoveResult = Coordinates(x: 0, y: 0)
            specifications.stubbedValidMovesResult = [validMoveResult]
            specifications.stubbedFlippedDiskCoordinatesByPlacingResult = [Coordinates(x: 1, y: 1)]
            // まだゲームが終わっていないことを設定
            specifications.isEndOfGame = false
            XCTAssertEqual(target.turn, .dark, "初期値の確認")
            // Then
            let placeDiskExpectation = expectation(description: "viewModelのplaceが呼ばれること")
            viewModel.invokedSetDiskDiskAtCoordinatesParameters = { (disk, coordinates) in
                placeDiskExpectation.fulfill()
                XCTAssertEqual(disk, .dark)
                XCTAssertEqual(coordinates, validMoveResult)
            }
            
            // When
            target.playTurnOfComputer()
            // Then
            XCTAssertEqual(darkIndicator.startAnimatingCount, 1, "darkのターンなのでdark側のindicatorがstart")
            XCTAssertEqual(lightIndicator.startAnimatingCount, 0)
            XCTAssertNil(target.playerCancellers[.light], "手番でない側はキャンセラーが設定されない")
            XCTAssertNotNil(target.playerCancellers[.dark], "手番のプレイヤーはキャンセラーが設定される")
            
            wait(for: [placeDiskExpectation], timeout: 3)
        }
        XCTContext.runActivity(named: "実行待機中にリセットされて実行キャンセルされる場合") { _ in
            // Given
            let viewModel = MockReversiViewModel()
            let specifications = MockReversiSpecifications()
            let darkIndicator = MockUIIndicatorView()
            let lightIndicator = MockUIIndicatorView()
            let repository = MockGameRepository()
            let target = ViewController()
            target.playerActivityIndicators = []
            target.playerActivityIndicators.append(darkIndicator)
            target.playerActivityIndicators.append(lightIndicator)
            target.specifications = specifications
            target.viewModel = viewModel
            target.gameRepository = repository
            let validMoveResult = Coordinates(x: 0, y: 0)
            specifications.stubbedValidMovesResult = [validMoveResult]
            XCTAssertEqual(target.turn, .dark, "初期値の確認")
            
            // When
            target.playTurnOfComputer()
            target.playerCancellers[.dark]?.cancel()
            // Then
            XCTAssertEqual(darkIndicator.startAnimatingCount, 1, "darkのターンなのでdark側のindicatorがstart")
            XCTAssertEqual(darkIndicator.stopAnimatingCount, 1, "実行中断でdark側のindicatorがstop")
            XCTAssertEqual(lightIndicator.startAnimatingCount, 0)
            XCTAssertEqual(lightIndicator.stopAnimatingCount, 0)
            XCTAssertNil(target.playerCancellers[.light], "手番でない側はキャンセラーが設定されない")
            XCTAssertNil(target.playerCancellers[.dark], "手番のプレイヤーはキャンセラーが実行済みなので廃棄される")
        }
    }
    
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
        target.sink()
        // Then
        let controlExpectation = expectation(description: "controlが更新されること")
        controlExpectation.expectedFulfillmentCount = 2
        target.playerControls.forEach { label in
            observation.append(label.observe(\.selectedSegmentIndex, changeHandler: { _, changed in
                XCTAssertEqual(label.selectedSegmentIndex, Player.manual.rawValue)
                controlExpectation.fulfill()
            }))
        }
        // Then
        let resetExpectation = expectation(description: "Viewのリセットがされること")
        mockBoard.resetCompletion = { resetExpectation.fulfill() }
        // When
        target.newGame()
        // Then
        XCTAssertEqual(target.turn, .dark)
        wait(for: [resetExpectation, controlExpectation], timeout: 0.01)
    }
    
    // MARK: Views
    
    func testUpdateCountLabels() {
        // Given
        let target = ViewController()
        let firstLabel = MockUILabel(frame: .zero)
        let lastLabel = MockUILabel(frame: .zero)
        target.playerControls = controls
        target.countLabels = [firstLabel, lastLabel]
        target.messageDiskView = DiskView(frame: .zero)
        target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
        target.messageDiskView.layoutIfNeeded()
        target.messageDiskView.layoutIfNeeded()
        target.messageDiskSizeConstraint.isActive = true
        target.messageDiskSize = 5
        target.messageLabel = UILabel(frame: .zero)
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
            let target = ViewController()
            target.messageDiskView = DiskView(frame: .zero)
            target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
            target.messageDiskView.layoutIfNeeded()
            target.messageDiskView.layoutIfNeeded()
            target.messageDiskSizeConstraint.isActive = true
            target.messageLabel = UILabel(frame: .zero)
            target.messageDiskSize = diskSize
            let displayData = MessageDisplayData(status: .playing(turn: .light))
            // Then
            let messageExpectation = expectation(description: "messageLabelが更新されること")
            observation.append(target.messageLabel.observe(\.text) { _, change in
                XCTAssertEqual(target.messageDiskView.disk, .light)
                XCTAssertEqual(target.messageLabel.text, "'s turn")
                XCTAssertEqual(target.messageDiskSizeConstraint.constant, diskSize)
                messageExpectation.fulfill()
            })
            // When
            target.updateMessageViews(with: displayData)
            wait(for: [messageExpectation], timeout: 0.1)
            
        }
        XCTContext.runActivity(named: "ゲーム終了") { _ in
            XCTContext.runActivity(named: "一方の勝ち") { _ in
                // Given
                let target = ViewController()
                target.messageDiskView = DiskView(frame: .zero)
                target.messageLabel = UILabel(frame: .zero)
                target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
                target.messageDiskView.layoutIfNeeded()
                target.messageDiskSizeConstraint.isActive = true
                target.messageLabel = UILabel(frame: .zero)
                target.messageDiskSize = diskSize
                // Then
                let messageExpectation = expectation(description: "messageLabelが更新されること")
                observation.append(target.messageLabel.observe(\.text) { _, change in
                    XCTAssertEqual(target.messageDiskView.disk, .dark)
                    XCTAssertEqual(target.messageLabel.text, " won")
                    XCTAssertEqual(target.messageDiskSizeConstraint.constant, diskSize)
                    
                    messageExpectation.fulfill()
                })
                
                target.updateMessageViews(with: MessageDisplayData(status: .ending(winner: .dark)))
                wait(for: [messageExpectation], timeout: 0.1)
                
            }
            XCTContext.runActivity(named: "引き分け") { _ in
                let target = ViewController()
                target.messageDiskView = DiskView(frame: .zero)
                target.messageLabel = UILabel(frame: .zero)
                target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
                target.messageDiskView.layoutIfNeeded()
                target.messageDiskSizeConstraint.isActive = true
                target.messageLabel = UILabel(frame: .zero)
                target.messageDiskSize = diskSize
                // Then
                let messageExpectation = expectation(description: "messageLabelが更新されること")
                observation.append(target.messageLabel.observe(\.text) { _, change in
                    XCTAssertEqual(target.messageDiskView.disk, .dark, "引き分けはdisk viewはdiskが切り替わらない")
                    XCTAssertEqual(target.messageDiskSizeConstraint.constant, 0, "messageDiskSizeを0にしてdiskViewを隠す")
                    XCTAssertEqual(target.messageLabel.text, "Tied")
                    messageExpectation.fulfill()
                })
                // When
                target.updateMessageViews(with: MessageDisplayData(status: .ending(winner: nil)))
                wait(for: [messageExpectation], timeout: 0.1)
            }
        }
    }
    
    // MARK: - Reversi logics
    
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
            let willPlaceCoordinates = Coordinates(x: 0, y: 0)
            let willPlaceSide = Disk.dark
            do {
                try target.placeDisk(willPlaceSide, atX: willPlaceCoordinates.x, y: willPlaceCoordinates.y, completion: { isFinished in
                    completionExpectation.fulfill()
                    XCTAssertTrue(isFinished)
                })
            } catch {
                XCTFail("成功する想定")
            }
            // Then
            XCTAssertEqual(mockBord.setDiskArgs, willSetDiskArgs, "viewに対して指定された順番でディスクのセットが実行される")
            XCTAssertEqual(mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.count, 1,
                           "diskのflipなどは全てviewModel内で行われるので呼び出しは1回のみ")
            mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.enumerated().forEach {
                XCTAssertEqual(willPlaceSide, $0.element.disk)
                XCTAssertEqual(willPlaceCoordinates.x, $0.element.x)
                XCTAssertEqual(willPlaceCoordinates.y, $0.element.y)
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
            let willPlaceCoordinates = Coordinates(x: 0, y: 0)
            let willPlaceSide = Disk.dark
            do {
                try target.placeDisk(willPlaceSide, atX: willPlaceCoordinates.x, y: willPlaceCoordinates.y, completion: { isFinished in
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
            
            XCTAssertEqual(mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.count, 1,
                           "diskのflipはviewModel内で行われるので呼び出しは1回のみ")
            mockViewModel.invokedSetDiskDiskAtCoordinatesParametersList.enumerated().forEach {
                XCTAssertEqual(willPlaceSide, $0.element.disk, "指定された順番でディスクのセットが実行される")
                XCTAssertEqual(willPlaceCoordinates.x, $0.element.x)
                XCTAssertEqual(willPlaceCoordinates.y, $0.element.y)
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
            target.countLabels = [.init(frame: .zero), .init(frame: .zero)]
            target.messageLabel = .init(frame: .zero)
            target.messageDiskView = DiskView(frame: .zero)
            target.messageDiskSizeConstraint = target.messageDiskView.widthAnchor.constraint(equalToConstant: 8)
            target.messageDiskView.layoutIfNeeded()
            target.messageDiskView.layoutIfNeeded()
            target.messageDiskSizeConstraint.isActive = true
            target.messageDiskSize = 5
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
            // Then
            let darkExpectation = expectation(description: "darkのプレイヤーの切り替えスイッチが書き変わること")
            observation.append(controls[Disk.dark.index].observe(\.selectedSegmentIndex, changeHandler: { _, _ in
                XCTAssertEqual(controls[0].selectedSegmentIndex, 0, "x01なので初手のプレイヤーは0")
                XCTAssertEqual(controls[Disk.dark.index].selectedSegmentIndex, 0, "x01なので初手のプレイヤーは0")
                darkExpectation.fulfill()
            }))
            let lightExpectation = expectation(description: "lightのプレイヤーの切り替えスイッチが書き変わること")
            observation.append(controls[Disk.light.index].observe(\.selectedSegmentIndex, changeHandler: { _, _ in
                XCTAssertEqual(controls[1].selectedSegmentIndex, 1, "x01なので後手のプレイヤーは1")
                XCTAssertEqual(controls[Disk.light.index].selectedSegmentIndex, 1, "x01なので後手のプレイヤーは1")
                lightExpectation.fulfill()
            }))
            // When
            target.sink()
            do {
                try target.loadGame()
            } catch {
                fatalError()
            }
            XCTAssertEqual(target.turn, .dark)
            wait(for: [lightExpectation, darkExpectation], timeout: 0.1)
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
        }
    }
}
