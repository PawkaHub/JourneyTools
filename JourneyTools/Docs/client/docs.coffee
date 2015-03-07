# Sortable list functionality
Template.docList.rendered = ->
  @$('#navigation').sortable
    axis: 'y'
    revert: 100
    stop: (e, ui) ->
      # get the dragged html element and the one before
      #   and after it
      el = ui.item.get(0)
      before = ui.item.prev().get(0)
      after = ui.item.next().get(0)
      # Here is the part that blew my mind!
      #  Blaze.getData takes as a parameter an html element
      #    and will return the data context that was bound when
      #    that html element was rendered!
      if !before
        #if it was dragged into the first position grab the
        # next element's data context and subtract one from the order
        newOrder = Blaze.getData(after).order - 1
      else if !after
        #if it was dragged into the last position grab the
        #  previous element's data context and add one to the order
        newOrder = Blaze.getData(before).order + 1
      else
        newOrder = (Blaze.getData(after).order + Blaze.getData(before).order) / 2
      #update the dragged Item's order
      Documents.update
        _id: Blaze.getData(el)._id
      ,
        $set:
          order: newOrder

Template.docList.helpers
  documents: ->
    Documents.find({},{sort:{order:1}})

Template.docItem.helpers
  level: ->
    words = @title.split(' ') if @title?
    # Find hashtags
    hashtags = @title.match(/#*([^a-zA-Z0-9 ]+?)/gi) if @title?
    #console.log 'hashtags',hashtags

    if hashtags
      #console.log 'words',words
      # Check the length of the hashtags to determine distance
      switch hashtags[0].length
        when 1 then 'h1'
        when 2 then 'h2'
        when 3 then 'h3'
        when 4 then 'h4'
        when 5 then 'h5'
        when 6 then 'h6'
        else ''
    else
      console.log 'empty'
  title: ->
    # Strip all hashtags
    title = @title.replace(/#*([^a-zA-Z0-9 ]+?)/gi, '') if @title?
    if title == '' || title == ' '
      'untitled'
    else
      title
  untitled: ->
    # Strip all hashtags
    title = @title.replace(/#*([^a-zA-Z0-9 ]+?)/gi, '') if @title?
    if title == '' || title == ' '
      'untitled'
    else
      ''
  current: ->
    if Session.equals("document", @_id)
      'active'
    else
      ''

Template.docItem.events =
  "click .navigationItem": (e) ->
    e.preventDefault()
    Session.set("document", @_id)

Template.editor.helpers
  docid: ->
    Session.get("document")

insertingTitle = false
deletingDocument = false
editable = false
window.shouldDelete = false

# Check if user is typing anything than the delete key, and prevent deletion if they are
#document.onkeydown = (e) ->
  #Is it a delete key? If so set the shouldDelete flag to true
  #console.log 'e.which',e.which
  #if e.keyCode == 8 || e.keyCode == 46
  #  console.log 'ShouldDelete!'
  #  window.shouldDelete = true
  #else
  #  console.log 'Nevermind!'
  #  window.shouldDelete = false

Template.editor.helpers
  load: ->
    document = Documents.findOne()
    if document
      #console.log 'doc exists'
      Session.set 'document', document._id
    else
      console.log 'no doc!'
  setupAce: ->
    (ace,doc) ->
      window.aceEditor = ace
      Session.set 'snapshot',doc.getText()

      #Listen for the delete key
      aceEditor.keyBinding.addKeyboardHandler (data, hash, keyString, keyCode, event) ->
          if keyCode == 8
            console.log 'Oh',data,hash,keyString,keyCode,event
            window.shouldDelete = true

      lines = doc.getText().split('\n')

      #Filter out everything that isn't a hashtag line
      lines = lines.filter (line) ->
        line.substring(0, 1) == '#'

      cursor = ace.getCursorPosition()

      window.doc = doc

      #console.log 'DOC LINES!',lines

      # Move the cursor to the 0 row/column position to avoid a negative cursor position error whenever we load in a new document
      ace.moveCursorTo(0,0)

      # Insert the title into the newly created document
      if ace.session.getValue().length == 0
        console.log 'Inserting title..'
        ace.getSession().setValue('#')
        ace.moveCursorTo(0,2)

      doc.on 'change', (op) ->
        #window.editable = true
        # Update the markdown preview
        Session.set 'snapshot',doc.getText()

        #console.log 'Change'

        lines = doc.getText().split('\n')
        cursor = ace.getCursorPosition()

        #Filter out everything that isn't a hashtag line
        lines = lines.filter (line) ->
          line.substring(0, 1) == '#'

        # Is the operation type an insert and is it a hashtag at the beginning of a new line? If so, create a new document
        if op && op[0] && op[0].i == "#" && cursor.column == 1 && cursor.row != 0
          current = Documents.findOne Session.get 'document'

          console.log 'Doop'

          if current

            # Is the current document sandwiched inbetween another document?
            nextDocument =
              Documents.find { order: $gt: current.order },
                sort: order: 1
                limit: 1
            nextDocument = nextDocument.fetch()[0]

            if nextDocument
              # Are we inbetween a top level? If so, half the order from the current document to place it underneath
              #distance = nextDocument.order + current.order / 2
              #console.log 'distance!',distance
              newOrder = (nextDocument.order + current.order) / 2
              #console.log 'DOCUMENT EXISTS AFTER CURRENT',nextDocument.order, newOrder
            else
              #console.log 'Increment normally'
              newOrder = current.order += 1

            ace.removeWordLeft()

            #console.log 'HASHTAG DETECTED! CREATE A NEW DOCUMENT',lines, newOrder
            Documents.insert
              title: op[0].i
              order: newOrder
            , (err,id) ->
              #console.log 'RESULT!', err, id
              return unless id
              # Remove hashtag
              #ace.removeWordLeft()
              Session.set 'document', id
              insertingTitle = true
        # Check if the operation type is a delete and is the document empty? If so, delete the document
        else if op && op[0] && op[0].d && doc.getText().length == 0
          #console.log 'Delete empty document!'

          current = Documents.findOne Session.get 'document'
          if current
            order = current.order

            prevDocument =
              Documents.find { order: $lt: current.order },
                sort: order: -1
                limit: 1
            prevDocument = prevDocument.fetch()[0]

            #console.log 'Checking if shouldDelete!',window.shouldDelete

            if window.shouldDelete
              console.log 'WILL DELETE!'
              # Only fire if there's more than one document
              Meteor.call('deleteDocument', Session.get('document'), (err,result) ->
                  console.log 'DELETED DOCUMENT!'
                  window.shouldDelete = false
                  # Switch to the prev document and delete the old one
                  if Documents.find().count() == 1
                    console.log 'Do nothing!'
                    Session.set 'document',Documents.findOne()._id
                  else
                    console.log 'Switch to previous!'
                    if prevDocument
                      Session.set 'document',prevDocument._id
              )

        else if op && op[0] && ace.session.getValue().length > 0 && cursor.row == 0

          #console.log 'Dwoop',ace.session.getValue().length

          # If it's another type of insert and the document isn't empty
          #console.log 'UPDATE DOCUMENT TITLE',doc.getText(),editable
          Documents.update
              _id: Session.get 'document'
            ,
              $set:
                title: lines[0]

  configAce: ->
    (ace) ->
      #console.log 'Renderer'
      # Set some options on the editor
      ace.setOption('theme','ace/theme/monokai')
      ace.setOption('highlightActiveLine',false)
      ace.setOption('showGutter',false)
      ace.setOption('showPrintMargin',false)
      ace.setOption('wrapBehavioursEnabled',true)
      ace.setOption('wrap',true)
      ace.setOption('vScrollBarAlwaysVisible',false)
      ace.setOption('hScrollBarAlwaysVisible',false)
      ace.setOption('scrollPastEnd',0.7)

      # Set the editor's scroll margin
      ace.renderer.setScrollMargin(30,0,0,0)
      # Focus the editor
      ace.focus()

Template.code.helpers
  input: ->
    Session.get 'snapshot'

# Global key events
window.onkeydown = (e) ->
  # F key?
  if e.ctrlKey and e.shiftKey and e.keyCode is 70
    # Enter fullscreen mode
    screenfull.toggle(document.documentElement)