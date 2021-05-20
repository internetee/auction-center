import consumer from "./consumer"

consumer.subscriptions.create("AuctionsChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log('Client is live')
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    $('#auctions_web_sockets').append('<div class="message">' + data.domain_name + '</div>')
    console.log("RECEIVED CONSOLE ++++++++")
    console.log(data)
    console.log("RECEIVED CONSOLE ++++++++")
  }
});
