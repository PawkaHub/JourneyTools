# counter starts at 0
Session.setDefault 'counter', 0
Template.editor.helpers counter: ->
  Session.get 'counter'
Template.editor.events 'click button': ->
  # increment the counter when button is clicked
  Session.set 'counter', Session.get('counter') + 1