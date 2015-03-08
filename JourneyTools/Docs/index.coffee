this.Documents = new Meteor.Collection("documents")
this.Bookmarks = new Meteor.Collection("bookmarks")

Meteor.methods
	deleteDocument: (id) ->
		if Documents.find().count() > 1
			Documents.remove(id)
			ShareJS.model.delete(id) unless @isSimulation # ignore error
	clearBookmarks: () ->
		Bookmarks.remove({})
	updateDocuments: (docInfo) ->
		#console.log 'refreshBookmarks called!',line
		Documents.update
				order: docInfo.order
			,
				$set:
					title: docInfo.title
					#hash: line.lineText.toLowerCase().replace(" ","-")
			,
				upsert: true
			, (err,id) ->
				#console.log 'RESULT!', err, id
				return unless id

	refreshBookmarks: (line) ->
		#console.log 'refreshBookmarks called!',line
		Bookmarks.update
				line: line.lineNumber
			,
				$set:
					title: line.lineText
					hash: line.lineText.toLowerCase().replace(" ","-")
			,
				upsert: true
			, (err,id) ->
				#console.log 'RESULT!', err, id
				return unless id

if Meteor.isServer
	if Documents.find().count() == 0
		Documents.insert
				title: ''
				order: 0
			, (err, id) ->
				return unless id