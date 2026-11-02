import Testing
@testable import TimeTracker

struct PaletteSelectionTests {
    @Test func startsWithNothingSelected() {
        #expect(PaletteSelection().index == nil)
    }

    @Test func downFromNoneSelectsTheFirstRow() {
        var selection = PaletteSelection()
        selection.moveDown(count: 3)
        #expect(selection.index == 0)
    }

    @Test func downClampsAtTheLastRow() {
        var selection = PaletteSelection()
        for _ in 0..<5 { selection.moveDown(count: 3) }
        #expect(selection.index == 2)
    }

    @Test func upFromTheFirstRowClearsTheSelection() {
        var selection = PaletteSelection()
        selection.moveDown(count: 3)
        selection.moveUp(count: 3)
        #expect(selection.index == nil)
    }

    @Test func upFromNoneStaysNone() {
        var selection = PaletteSelection()
        selection.moveUp(count: 3)
        #expect(selection.index == nil)
    }

    @Test func upMovesBackOneRow() {
        var selection = PaletteSelection()
        selection.moveDown(count: 3)
        selection.moveDown(count: 3)
        selection.moveUp(count: 3)
        #expect(selection.index == 0)
    }

    @Test func movingWithNoRowsKeepsNothingSelected() {
        var selection = PaletteSelection()
        selection.moveDown(count: 0)
        #expect(selection.index == nil)
    }

    @Test func resetClearsTheSelection() {
        var selection = PaletteSelection()
        selection.moveDown(count: 3)
        selection.reset()
        #expect(selection.index == nil)
    }
}
