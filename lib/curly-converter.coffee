RubyBlockConverter = require './ruby-block-converter'

module.exports =
class CurlyConverter extends RubyBlockConverter

  scanForDo: (editor, range) ->
    # scan backwards for first do
    startRange = null
    editor.buffer.backwardsScanInRange /\sdo\b/, range, (obj) ->
      startRange = obj.range
      obj.stop()
    startRange

  scanForEnd: (that, editor, range) ->
    # scan for end, and matching dos
    matchRanges = []
    editor.buffer.scanInRange /\bend\b/g, range, (obj) ->
      that.endCount++
      matchRanges.push obj.range
    editor.buffer.scanInRange /\sdo\b/g, range, (obj) ->
      that.startCount++
    matchRanges

  findDo: ->
    startRange = null
    # look on current line
    # only looks left because it makes finding the correct
    # end easier with nested blocks
    @editor.setCursorBufferPosition @initialCursor
    @editor.selectToFirstCharacterOfLine()
    range = @editor.getSelectedBufferRange()
    startRange = @scanForDo(@editor, range)
    # interate up lines until do is found or reached max levels
    i = 0
    while startRange == null && i < @maxLevels && @notFirstRow(@editor)
      # move up line up
      @editor.moveCursorUp()
      @editor.moveCursorToEndOfLine()
      @editor.selectToFirstCharacterOfLine()
      r = @editor.getSelectedBufferRange()
      startRange = @scanForDo(@editor, r)
      i += 1
    startRange

  findEnd: (startRange) ->
    # TODO: if couldn't find matching end, go back to findDo and move up one
    that = this
    endRange = null
    matchRanges = []
    # make sure there is no end between the do and cursor
    # move after end of current word
    startingPoint = [startRange.end.row, startRange.end.column]
    @editor.setCursorBufferPosition startingPoint
    @editor.selectToEndOfLine()
    range = @editor.getSelectedBufferRange()
    lineMatches = @scanForEnd(that, @editor, range)
    if lineMatches.length > 0
      matchRanges.push lineMatches
    endRange = matchRanges[@endCount - 1][0] if @foundMatchingEnd()

    if endRange == null
      # initial cursor range
      i = 0
      while !@foundMatchingEnd() && endRange == null && i < @maxLevels && @notLastRow(@editor)
        # move down a line
        @editor.moveCursorDown 1
        @editor.moveCursorToEndOfLine()
        @editor.selectToFirstCharacterOfLine()
        r = @editor.getSelectedBufferRange()
        lineMatches = @scanForEnd(that, @editor, r)
        if lineMatches.length > 0
          matchRanges.push lineMatches
        endRange = matchRanges[@endCount - 1][0] if @foundMatchingEnd()
        i += 1
    # cancel if end found on a line before cursor
    if endRange != null && @initialCursor != null
      if endRange.start.row < @initialCursor.row
        endRange = null
    endRange

  replaceBlock: (startRange, endRange) ->
    @editor.buffer.backwardsScanInRange /end/, endRange, (obj) ->
      match = obj.matchText.match(/([\W])end(.*)/, '')
      if match != null
        beforeEnd = match[1]
        afterEnd = match[2]
      obj.replace (beforeEnd ?= '') + '}' + (afterEnd ?= '')
      obj.stop()
    @editor.buffer.scanInRange /do/, startRange, (obj) ->
      afterDo = obj.matchText.replace(/do/, '') || ''
      obj.replace '{' + afterDo
      obj.stop()

  resetCursor: (collapsed, startRange=null) ->
    if collapsed
      @editor.moveCursorToEndOfLine()
    else if @initialCursor != null
      @editor.setCursorBufferPosition @initialCursor

  collapseBlock: (startRange, endRange) ->
    # see how many lines between start and end
    lineSeparation = endRange.start.row - startRange.start.row

    if 1 <= lineSeparation and lineSeparation <= 2
      # join lines if it makes sense
      @editor.setCursorBufferPosition startRange.start
      @editor.moveCursorToFirstCharacterOfLine()
      @editor.selectDown lineSeparation
      @editor.selectToEndOfLine()
      @editor.getSelection().joinLines()
      collapsed = true
