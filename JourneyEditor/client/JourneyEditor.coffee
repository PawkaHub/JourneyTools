# counter starts at 0
Session.setDefault 'counter', 0
Template.editor.helpers counter: ->
  Session.get 'counter'
Template.editor.events 'click button': ->
  # increment the counter when button is clicked
  Session.set 'counter', Session.get('counter') + 1

# Global key events
window.onkeydown = (e) ->
  # M key?
  if e.ctrlKey and e.shiftKey and e.keyCode is 77
    # Enter fullscreen mode
    console.log 'Toggle me!'
    domain = 'http://localhost:1337'
    message = 'resize'
    window.parent.postMessage message, domain