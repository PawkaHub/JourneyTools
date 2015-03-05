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
      #else
      #  newOrder = (Blaze.getData(after).order + Blaze.getData(before).order) / 2
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
    words = @title.split(' ')
    console.log 'words',words
    # Check the length of the hashtags to determine distance
    switch words[0].length
      when 1 then 'h1'
      when 2 then 'h2'
      when 3 then 'h3'
      when 4 then 'h4'
      when 5 then 'h5'
      when 6 then 'h6'
      else ''
  title: ->
    # Strip all hashtags
    regexp = new RegExp('#([^\\s]*)','g');
    title = @title.replace(regexp, '')
    title
  current: ->
    Session.equals("document", @_id)

Template.docItem.events =
  "click a": (e) ->
    e.preventDefault()
    Session.set("document", @_id)

Template.editor.helpers
  docid: ->
    Session.get("document")

insertingTitle = false

Template.editor.helpers
  load: ->
    document = Documents.findOne()
    if document
      console.log 'doc exists'
      Session.set 'document', document._id
    else
      console.log 'no doc!'
  setupAce: ->
    (ace,doc) ->
      window.aceEditor = ace
      # Retain cursor position so it's not at bottom of document
      ace.moveCursorTo(0)
      # Setup an added event listener
      Session.set 'snapshot',doc.getText()

      #console.log 'CURRENT DOC!',doc
      # Insert the title into the newly created document
      if insertingTitle
        console.log 'Inserting title..'
        ace.getSession().setValue('#')
        ace.moveCursorTo(1)
        insertingTitle = false

      if doc.getText().length == 0
        console.log 'Document is empty, give it some text'
        insertingTitle = true
        ace.getSession().setValue('#')
        ace.moveCursorTo(1)
        insertingTitle = false

      doc.on 'change', (op) ->
        # Update the markdown preview
        Session.set 'snapshot',doc.getText()

        lines = doc.getText().split('\n')
        cursor = ace.getCursorPosition()

        #Filter out everything that isn't a hashtag line
        lines = lines.filter (line) ->
          line.substring(0, 1) == '#'

        # Check if the operation type is a delete and is the document empty? If so, delete the document
        if op && op[0] && op[0].d && doc.getText().length == 0
          #console.log 'Delete empty document!'
          current = Documents.findOne Session.get 'document'
          if current
            order = current.order

            prevDocument =
              Documents.find { order: $lt: current.order },
                sort: order: -1
                limit: 1
            prevDocument = prevDocument.fetch()[0]
            console.log 'DELETING DOCUMENT!'

            # Only fire if there's more than one document

            Meteor.call('deleteDocument', Session.get('document'), (err,result) ->
                console.log 'DELETED DOCUMENT!'
                # Switch to the prev document and delete the old one
                if Documents.find().count() == 1
                  console.log 'Do nothing!'
                  Session.set 'document',Documents.findOne()._id
                else
                  console.log 'Switch to previous!'
                  Session.set 'document',prevDocument._id
            )

        # Is the operation type an insert and is it a hashtag at the beginning of a new line? If so, create a new document
        if op && op[0] && op[0].i == "#" && !insertingTitle && cursor.column == 1
          current = Documents.findOne Session.get 'document'
          if current

            # Is the current document sandwiched inbetween another document?
            nextDocument =
              Documents.find { order: $gt: current.order },
                sort: order: 1
                limit: 1
            nextDocument = nextDocument.fetch()[0]

            if nextDocument
              # Are we inbetween a top level?
              distance = nextDocument.order - current.order
              console.log 'distance!',distance
              newOrder = current.order += 0.0000001
              console.log 'DOCUMENT EXISTS AFTER CURRENT',nextDocument.order, newOrder
            else
              console.log 'Increment normally'
              newOrder = current.order += 1

            console.log 'HASHTAG DETECTED! CREATE A NEW DOCUMENT',lines, newOrder
            Documents.insert
              title: op[0].i
              order: newOrder
            , (err,id) ->
              #console.log 'RESULT!', err, id
              return unless id
              # Remove hashtag
              ace.removeWordLeft()
              Session.set 'document', id
              insertingTitle = true
        else if op && op[0] && doc.getText().length >= 2
          # If it's another type of insert and the document isn't empty
          console.log 'UPDATE DOCUMENT TITLE',lines
          Documents.update
              _id: Session.get 'document'
            ,
              $set:
                title: lines[0]

  configAce: ->
    (ace) ->
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