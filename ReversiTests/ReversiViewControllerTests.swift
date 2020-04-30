import XCTest
@testable import Reversi

class ReversiViewControllerTests: XCTestCase {
    
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

    func testSideWithMoreDisks() {
        XCTContext.runActivity(named: "引き分け") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            mockBord.dummyDisks = [
                Coordinates(x: 0, y: 0): .light,
                Coordinates(x: 1, y: 1): .dark,
            ]
            XCTAssertNil(target.sideWithMoreDisks())
        }
        XCTContext.runActivity(named: "lightが多い") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            mockBord.dummyDisks = [
                Coordinates(x: 0, y: 0): .light,
                Coordinates(x: 1, y: 0): .light,
                Coordinates(x: 1, y: 1): .dark,
            ]
            XCTAssertEqual(target.sideWithMoreDisks(), .light)
        }
        
        XCTContext.runActivity(named: "darkが多い") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            mockBord.dummyDisks = [
                Coordinates(x: 0, y: 0): .light,
                Coordinates(x: 1, y: 0): .dark,
                Coordinates(x: 1, y: 1): .dark,
            ]
            XCTAssertEqual(target.sideWithMoreDisks(), .dark)
        }
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
            Coordinates(x: mockBord.width, y: mockBord.height): .dark,
            Coordinates(x: mockBord.width + 1, y: mockBord.height + 1): .light,
        ]
        XCTAssertTrue(target.validMoves(for: .light).contains(where: ({ $0.x == 3 && $0.y == 3 })), "範囲内")
        XCTAssertFalse(target.validMoves(for: .light).contains(where: ({ ($0.x == mockBord.width - 1) && ($0.y == mockBord.height - 1) })), "範囲外")
    }
    
    // MARK: - Save and Load
    
    var controls: [UISegmentedControl] {
        Disk.sides.enumerated().map {
            let control = UISegmentedControl(items: nil)
            control.insertSegment(withTitle: "Manual", at: 0, animated: false)
            control.insertSegment(withTitle: "Computer", at: 1, animated: false)
            control.selectedSegmentIndex = $0.offset
            return control
        }
    }
    
    func testSaveGame() {
        // Given
        let boardView = BoardView(frame: .zero)
        /*
         x00
         --------
         --------
         --------
         --xxx---
         ---xo---
         --------
         --------
         --------
         */
        boardView.setDisk(.dark, atX: 2, y: 3, animated: false)
        boardView.setDisk(.dark, atX: 3, y: 3, animated: false)
        boardView.setDisk(.dark, atX: 4, y: 3, animated: false)
        boardView.setDisk(.dark, atX: 3, y: 4, animated: false)
        boardView.setDisk(.light, atX: 4, y: 4, animated: false)
        let target = ViewController()
        target.boardView = boardView
        let controls = self.controls
        target.playerControls = controls
        let mockIO = MockFileIO()
        target.gameRepository = GameRepositoryImplementation(fileIO: mockIO)
        // When
        do {
            try target.saveGame()
        } catch {
            fatalError()
        }
        // 最後の行に開業が含まれるので空白行が必要
        XCTAssertEqual(mockIO.written!, """
                                        x01
                                        --------
                                        --------
                                        --------
                                        --xxx---
                                        ---xo---
                                        --------
                                        --------
                                        --------

                                        """)
        
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
            let mockIO = MockFileIO()
            target.gameRepository = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            mockIO.saved = """
                        x01
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------

                        """
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
            XCTAssertEqual(target.turn, .dark, "x01なのでdarkの手番")
            XCTAssertEqual(controls[0].selectedSegmentIndex, 0, "x01なので初手のプレイヤーは0")
            XCTAssertEqual(controls[1].selectedSegmentIndex, 1, "x01なので後手のプレイヤーは1")
        }
        XCTContext.runActivity(named: "y軸の盤面が異常データ") { _ in
            // Given
            let boardView = BoardView(frame: .zero)
            let target = ViewController()
            target.boardView = boardView
            target.playerControls = controls
            let mockIO = MockFileIO()
            target.gameRepository = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            // y軸の段が9個あり、定義より一行だけ多い
            mockIO.saved = """
                        x01
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------
                        --------

                        """
            // When
            do {
                try target.restoreBoardView()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "x軸の盤面が異常データ") { _ in
            // Given
            let boardView = BoardView(frame: .zero)
            let target = ViewController()
            target.boardView = boardView
            target.playerControls = controls
            let mockIO = MockFileIO()
            target.gameRepository = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            // x軸の幅が9あり、定義より一つだけ多い
            mockIO.saved = """
                        x01
                        ---------
                        ---------
                        ---------
                        --xxx----
                        ---xo----
                        ---------
                        ---------
                        ---------

                        """
            // When
            do {
                try target.restoreBoardView()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "盤面が空") { _ in
            // Given
            let boardView = BoardView(frame: .zero)
            let target = ViewController()
            target.boardView = boardView
            target.playerControls = controls
            let mockIO = MockFileIO()
            target.gameRepository = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            // x軸の幅が9あり、定義より一つだけ多い
            mockIO.saved = ""
            // When
            do {
                try target.restoreBoardView()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "disk simbolが不正") { _ in
            // Given
            let boardView = BoardView(frame: .zero)
            let target = ViewController()
            target.boardView = boardView
            target.playerControls = controls
            let mockIO = MockFileIO()
            target.gameRepository = GameRepositoryImplementation(fileIO: mockIO)
            mockIO.saved = """
                        y01
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------

                        """
            // When
            do {
                try target.restoreBoardView()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "player simbolが不正") { _ in
            // Given
            let boardView = BoardView(frame: .zero)
            let target = ViewController()
            target.boardView = boardView
            target.playerControls = controls
            let mockIO = MockFileIO()
            target.gameRepository = GameRepositoryImplementation(fileIO: mockIO)
            mockIO.saved = """
                        x09
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------

                        """
            // When
            do {
                try target.restoreBoardView()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
    }
}
