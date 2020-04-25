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
            // 範囲外
            Coordinates(x: mockBord.width, y: mockBord.height): .dark,
            Coordinates(x: mockBord.width + 1, y: mockBord.height + 1): .light,
        ]
        XCTAssertTrue(target.validMoves(for: .light).contains(where: ({ $0.x == 3 && $0.y == 3 })), "範囲内")
        XCTAssertTrue(target.validMoves(for: .light).contains(where: ({ ($0.x == mockBord.width - 1) && ($0.y == mockBord.height - 1) })), "範囲外 - 現在選択できるので後ほど座標を返さないように修正")
    }
    
    // MARK: - Save and Load
    func testSaveGame() {
        let target = ViewController()
        let fileIO = FileIO(path: target.path)
        
    }
    
    func testLoadGame() {
        
    }
}
