REGEX_DO_ONLY = /\sdo$/
REGEX_DO_BAR  = /\sdo\s\|/
REGEX_END     = /end$/

module.exports =
class CurlyConverter
  foundStart = false
  foundEnd   = false
  
  constructor: (editor) ->
    @editor = editor
    foundStart = false
    foundEnd   = false
    @replaceDo()
    @replaceEnd() if foundStart
  
  foundBlock: ->
    foundStart && foundEnd
      
  replaceDo: ->
    # find do
    @editor.moveCursorUp()
    @editor.moveCursorToEndOfLine()
    @editor.selectToFirstCharacterOfLine()
    
    range = @editor.getSelectedBufferRange()
    @editor.buffer.scanInRange REGEX_DO_ONLY, range, (obj) ->
      # console.log 'found do only'
      foundStart = true
      obj.replace " {"
      obj.stop()
    
    unless foundStart
      @editor.buffer.scanInRange REGEX_DO_BAR, range, (obj) ->
        # console.log 'found do bar'
        foundStart = true
        obj.replace " { |"
        obj.stop()

  replaceEnd: ->
    # find end
    @editor.moveCursorDown 2
    @editor.moveCursorToEndOfLine()
    @editor.selectToFirstCharacterOfLine()
    range = @editor.getSelectedBufferRange()
    @editor.buffer.scanInRange REGEX_END, range, (obj) ->
      # console.log 'found end'
      foundEnd = true
      obj.replace ''
      obj.stop()
    if foundEnd
      @editor.deleteLine()
      @editor.moveCursorUp 1
      @editor.moveCursorToFirstCharacterOfLine()
      @editor.selectToEndOfLine()
      selection = @editor.getSelection()
      selectedLine = selection.getText()
      @editor.deleteLine()
      @editor.moveCursorUp 1
      @editor.moveCursorToEndOfLine()
      selection = @editor.getSelection()
      selection.insertText ' ' + selectedLine + ' }'
