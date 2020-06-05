// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.

import { createConsumer } from "@rails/actioncable"

let consumer = createConsumer("http://localhost:4000/cable");

const createChannel = (...args) => {
  if (!consumer) {
    consumer = createConsumer("http://localhost:4000/cable");
  }

  if (consumer.disconnected === true) {
    consumer.connect();
  }

  return consumer.subscriptions.create(...args);
};

export default createChannel;
