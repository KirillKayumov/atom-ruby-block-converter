fs = require 'fs-plus'
path = require 'path'
temp = require 'temp'
{WorkspaceView} = require 'atom'

describe 'RubyBlockConverter', ->
  [editor, buffer] = []

  beforeEach ->
    directory = temp.mkdirSync()
    atom.project.setPath(directory)
    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model
    filePath = path.join(directory, 'example.rb')
    atom.config.set('editor.tabLength', 2)

    waitsForPromise ->
      atom.workspace.open(filePath).then (e) ->
        editor = e
        buffer = editor.getBuffer()
        editor.setTabLength(2)
        # editor.setSoftTabs true

    waitsForPromise ->
      atom.packages.activatePackage('language-ruby')

    waitsForPromise ->
      atom.packages.activatePackage('ruby-block-converter')

  describe 'toDoEnd', ->
    it 'does not change an empty file', ->
      atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
      expect(editor.getText()).toBe ''

    describe 'when no variable', ->
      it 'converts it to a multi line block with do-end', ->
        editor.insertText("1.times { puts 'hello' }\n")
        editor.moveCursorUp 2
        editor.moveCursorRight() for num in [0...11]
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe "1.times do\n  puts 'hello'\nend\n"

    describe 'when a variable', ->
      it 'converts it to a multi line block with do-end', ->
        editor.insertText("1.times { |bub| puts 'hello' }\n")
        editor.moveCursorUp 2
        editor.moveCursorRight() for num in [0...11]
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe "1.times do |bub|\n  puts 'hello'\nend\n"

    describe 'when nested', ->
      it 'converts it to a multi line block with do-end', ->
        textStart = "1.times do |bub|\n  2.times { |cow| puts bub + cow }\nend\n"
        textEnd = "1.times do |bub|\n  2.times do |cow|\n    puts bub + cow\n  end\nend\n"
        editor.insertText textStart
        editor.moveCursorUp 2
        editor.moveCursorToEndOfLine()
        editor.moveCursorLeft 1
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe textEnd

    describe 'when more than one line', ->
      it 'converts to brackets only', ->
        startText = "1.times {\n  puts 'hello'\n  puts 'world'\n}\n"
        endText = "1.times do\n  puts 'hello'\n  puts 'world'\nend\n"
        editor.insertText(startText)
        editor.moveCursorUp 2
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe endText

    describe 'when cursor at end of line', ->
      it 'converts it to a multi line block with do-end', ->
        editor.insertText("1.times { puts 'hello' }\n")
        editor.moveCursorUp 2
        editor.moveCursorToEndOfLine()
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe "1.times do\n  puts 'hello'\nend\n"

    describe 'when cursor at one line below }', ->
      it "doesn't convert it", ->
        startText = "1.times { puts 'hello' }\n\n"
        editor.insertText(startText)
        editor.moveCursorUp 1
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe startText

    describe 'when no new line', ->
      it 'converts it to a multi line block with do-end', ->
        editor.insertText("1.times { puts 'hello' }")
        editor.moveCursorUp 2
        editor.moveCursorRight() for num in [0...11]
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe "1.times do\n  puts 'hello'\nend"

    describe 'when cursor right of {', ->
      it 'converts it to a multi line block with do-end', ->
        startText = "1.times { puts 'hello' }\n"
        endText = "1.times do\n  puts 'hello'\nend\n"
        editor.insertText(startText)
        editor.moveCursorUp 1
        editor.moveCursorRight() for num in [0...13]
        i = 0
        while i < 9
          editor.moveCursorRight()
          i += 1
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe endText

    describe 'when cursor left of {', ->
      it "doesn't convert it", ->
        startText = "1.times { puts 'hello' }\n"
        editor.insertText(startText)
        editor.moveCursorUp 1
        editor.moveCursorRight()for num in [0...8]
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe startText

    describe 'when empty lines before block', ->
      it 'properly indents', ->
        nls = "\n\n\n\n\n\n\n\n  "
        startText = "1.times do#{nls}1.times { puts 'hello' }\nend\n"
        endText   = "1.times do#{nls}1.times do\n    puts 'hello'\n  end\nend\n"
        editor.insertText(startText)
        editor.moveCursorUp 2
        editor.moveCursorRight() for num in [0...13]
        atom.workspaceView.trigger 'ruby-block-converter:toDoEnd'
        expect(editor.getText()).toBe endText