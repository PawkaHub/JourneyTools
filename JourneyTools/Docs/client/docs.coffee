Meteor.startup ->
  window.Current = null
  # Set up delete observer to handle remote deletion of documents
  Documents.find({},{sort:{order:1}}).observe
    removed:(doc) ->

      #console.log 'Removed!', doc

      order = doc.order

      prevDocument =
        Documents.find { order: $lt: doc.order },
          sort: order: -1
          limit: 1
      prevDocument = prevDocument.fetch()[0]

      #console.log 'Switch to previous!'
      if prevDocument
        Session.set 'document',prevDocument._id

# Sortable list functionality
Template.docList.rendered = ->
  self = this
  #Automatically set current variable to update whenever the document session is changed
  self.autorun((computation)->
    if Documents.findOne(Session.get('document'))
      window.Current = Documents.findOne(Session.get('document'))
  )
  # Set up scroll event
  @$('#navigation').scroll (e) ->
    #Use the get elementFromPoint function to determine what element is currently scrolled past our y threshold.
    scrollItem = document.elementFromPoint(0,20)
    #Get the data context from our scroll item
    scrollItemData = Blaze.getData(scrollItem)
    # Check if the scrollItemData is different from our current document, and if it is, switch the document to be the new one
    if scrollItemData && scrollItemData._id != Session.get 'document'
      Session.set 'document', scrollItemData._id
  # Set up sortable navigation
  @$('#navigation').sortable
    axis: 'y'
    revert: 100
    stop: (e, ui) ->
      # get the dragged html element and the one before and after it
      el = ui.item.get(0)
      before = ui.item.prev().get(0)
      after = ui.item.next().get(0)
      if !before
        #if it was dragged into the first position grab the next element's data context and subtract one from the order
        newOrder = Blaze.getData(after).order - 1
      else if !after
        #if it was dragged into the last position grab the previous element's data context and add one to the order
        newOrder = Blaze.getData(before).order + 1
      else
        newOrder = (Blaze.getData(after).order + Blaze.getData(before).order) / 2
      #update the dragged Document's order
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
        else 'h1'
    else
      'h1'
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
    # Save cursor position
    Session.set("document", @_id)

Template.editor.helpers
  docid: ->
    Session.get("document")

updateDocs = (current) ->
  #console.log 'updateDocs'
  # Create the new documents based on what docs have been generated in the pastedDocs array
  for doc, i in window.pastedDocs
    #console.log 'doc!',doc
    # First, let's convert the object to string so that it's all text that we can work with for ace's setValue method.
    docText = doc.title + "\n" + doc.body.join('\n')
    #console.log 'docText!',docText
    # Don't run if it's the topHeader, as we've already handled that in the paste function and this is only for new document creation handling
    if doc.isTopHeader
      #Just update the title
      updateTitle(doc.title)
    else
      # Since it's not a top level, we require a new document to be made, and we shall do so here, whilst populating the new document with text from the pasted content.
      #console.log 'CREATE A NEW DOCUMENT!'

      if current
        # Is the current document sandwiched inbetween another document?
        nextDocument =
          Documents.find { order: $gt: current.order },
            sort: order: 1
            limit: 1
        nextDocument = nextDocument.fetch()[0]

        if nextDocument
          # Are we inbetween a top level? If so, half the order from the current document to place it underneath
          newOrder = (nextDocument.order + current.order) / 2
        else
          newOrder = current.order += 1

        #Create an empty doc for now
        createDoc(doc.title,newOrder,docText)

updateTitle = (title) ->
  Documents.update
      _id: Session.get 'document'
    ,
      $set:
        title: title

createDoc = (title,order,docText) ->
  Documents.insert
      title: title
      order: order
      docText: docText
    , (err,id) ->
      return unless id
      Session.set 'document', id

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
      #Get current document -> We do it this way to avoid a weird session bug where the document and it's preview will get out of sync
      current = Current

      #Check for if there's docText and populate the text accordingly if the document is empty
      if current and doc
        if current.docText and doc.getText().length is 0
          #console.log 'Updating docText!',current
          ace.getSession().setValue(current.docText)
          # Remove the docText from the document so that it doesn't fire again on new document changes
          Documents.update
              _id: current._id
            ,
              $unset:
                docText: ''

      #Move cursor to end of file
      ace.selection.moveCursorFileEnd()

      #Get cursor position
      cursor = ace.getCursorPosition()

      #Add delete command
      ace.commands.addCommand
        name: 'deleteDocument'
        bindKey:
          win: 'Backspace'
          mac: 'Backspace'
        exec: (editor) ->
          if doc.getText().length is 0
            #If document is empty, delete document
            #console.log 'DeleteDocument!'
            if current
              order = current.order
              prevDocument =
                Documents.find { order: $lt: current.order },
                  sort: order: -1
                  limit: 1
              prevDocument = prevDocument.fetch()[0]

              # Only fire if there's more than one document
              Meteor.call('deleteDocument', Session.get('document'), (err,result) ->
                  #console.log 'DELETED DOCUMENT!'
                  # Switch to the prev document and delete the old one, if a previous document exists. Otherwise, revert to the default
                  #if Documents.find().count() is 1
                  #console.log 'Do nothing!'
                  #Session.set 'document',Documents.findOne()._id
                  unless Documents.find().count() is 1
                    #console.log 'Switch to previous!'
                    if prevDocument
                      Session.set 'document',prevDocument._id
                    else
                      # Go to the first document
                      Documents.findOne()._id
              )
          else
            #Just run the normal backspace function
            ace.remove('left')

      #Add hashtag command
      ace.commands.addCommand
        name: 'createDocument'
        bindKey:
          win: '#'
          mac: '#'
        exec: (editor) ->
          if cursor.column is 0 and cursor.row isnt 0
            console.log 'CreateDocument!',editor
            #Create a new document
            if current
              # Is the current document sandwiched inbetween another document?
              nextDocument =
                Documents.find { order: $gt: current.order },
                  sort: order: 1
                  limit: 1
              nextDocument = nextDocument.fetch()[0]

              if nextDocument
                # Are we inbetween a top level? If so, half the order from the current document to place it underneath
                newOrder = (nextDocument.order + current.order) / 2
              else
                newOrder = current.order += 1

              createDoc('',newOrder, '#')
          else
            #Just run the normal # insert function
            ace.insert('#')

      #Listen for paste events and create documents accordingly
      ace.on 'paste', (e) ->
        if e.text
          lines = e.text.split('\n')
          headerIndex = 0
          window.pastedDocs = []
          #console.log 'Trigger bulk document creation!',lines
          # Iterate over all the lines in the document and find hashtags
          for line, i in lines
            #console.log 'line!',line
            if line and line.substring(0, 1) is '#'
              e.text = null
              #console.log 'hashtag header! Trigger document creation!',line,i
              # Is it the first hashtag in the header?
              # Create a doc
              docInfo =
                title: line
                body: []

              window.pastedDocs.push docInfo
              if i is 0 and ace.selection.getRange().start.row is 0 and ace.selection.getRange().start.column is 0
                #e.text = line
                headerIndex = i
                # Is the header position at the start of the document? NOTE: WILL HAVE TO DO A BETTER CHECK FOR THIS AS COPYING THE SAME TEXT ON A DIFFERENT LINE WILL PASTE IT NORMALLY, WHICH IS NOT WHAT WE WANT
                docInfo.isTopHeader = true
                #headerLine = line
                #ace.getSession()
              else
                #console.log 'Normal header! Create document!',line,i
                headerIndex = i
            else if i > headerIndex
              #console.log 'It\'s body text!',line,i,headerIndex
              if docInfo
                docInfo.body.push line

          for doc, i in window.pastedDocs
            #console.log 'doc!',doc
            # First, let's convert the object to string so that it's all text that we can work with for ace's setValue method.
            docText = doc.title + "\n" + doc.body.join('\n')
            if doc.isTopHeader
              # Since it's the same document, we don't need to create a new one and can simply let the paste proceed as normal
              #e.text = docText
              ace.getSession().setValue(docText)

          if window.pastedDocs.length
            # Call updateDocs after a set period of time
            updateDocs(current)
        #console.log 'Pasted!',e.text
        Session.set 'snapshot',ace.getSession().getValue()

      #Keep document changes in sync
      ace.keyBinding.addKeyboardHandler (data, hash, keyString, keyCode, event) ->
        #console.log 'change!'
        # Always update the title based on what the first line is
        #console.log 'Change!',e
        #if doc and doc.getText
          #Session.set 'snapshot',ace.getSession().getValue()
        title = ace.getSession().getLine(0)
        updateTitle(title)
        cursor = ace.getCursorPosition()

      Session.set 'snapshot',ace.getSession().getValue()

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
    Session.get('snapshot')

# Global key events
window.onkeydown = (e) ->
  # F key?
  if e.ctrlKey and e.shiftKey and e.keyCode is 70
    # Enter fullscreen mode
    screenfull.toggle(document.documentElement)

window.onkeyup = (e) ->
  Session.set 'snapshot',window.aceEditor.getSession().getValue()