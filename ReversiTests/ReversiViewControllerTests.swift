import XCTest
@testable import Reversi

class ReversiViewControllerTests: XCTestCase {
    
    var dummyDisks: [Path: Disk] {
        return [
            Path(x: 0, y: 0): Disk.dark,
            Path(x: 1, y: BoardView().height - 1): Disk.light,
            Path(x: BoardView().width - 1, y: 2): Disk.light,
            // 範囲外のデータ
            Path(x: 1, y: BoardView().height): Disk.light,
            Path(x: BoardView().width, y: 1): Disk.light,
        ]
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCountDisks() {
        // Given
        let target = ViewController()
        let mockBord = MockBoardView(frame: .zero)
        target.boardView = mockBord
        let dummyDisks = [
            Path(x: 0, y: 0): Disk.dark,
            Path(x: 1, y: BoardView().height - 1): Disk.light,
            Path(x: BoardView().width - 1, y: 2): Disk.light,
            // 範囲外のデータ
            Path(x: 1, y: BoardView().height): Disk.light,
            Path(x: BoardView().width, y: 1): Disk.light,
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
                Path(x: 0, y: 0): .light,
                Path(x: 1, y: 1): .dark,
            ]
            XCTAssertNil(target.sideWithMoreDisks())
        }
        XCTContext.runActivity(named: "lightが多い") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            mockBord.dummyDisks = [
                Path(x: 0, y: 0): .light,
                Path(x: 1, y: 0): .light,
                Path(x: 1, y: 1): .dark,
            ]
            XCTAssertEqual(target.sideWithMoreDisks(), .light)
        }
        
        XCTContext.runActivity(named: "darkが多い") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            mockBord.dummyDisks = [
                Path(x: 0, y: 0): .light,
                Path(x: 1, y: 0): .dark,
                Path(x: 1, y: 1): .dark,
            ]
            XCTAssertEqual(target.sideWithMoreDisks(), .dark)
        }
    }
    
    func testCanPlaceDisk() {
        XCTContext.runActivity(named: "盤面にDiskがない") { _ in
            // Given
            let target = ViewController()
            let mockBord = MockBoardView(frame: .zero)
            target.boardView = mockBord
            mockBord.dummyDisks = [:]
            XCTAssertFalse(target.canPlaceDisk(.dark, atX: 0, y: 0))
        }
    }

}
