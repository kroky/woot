Woot
====

Collaborative rich text editor for the web. Woot provides plain textarea and Quill adapters to allow two or more web browsers to sync and dynamically edit plain or rich text collaboratively.

Operation
---------

It is based on the WOOT framework described in [this paper](https://hal.inria.fr/file/index/docid/71240/filename/RR-5580.pdf).

WOOT (WithOut Operation Transformation) framework and algorithm is designed to ensure intention consistency without following the OT approach. It easily scales to large peer-to-peer networks as main synchronization work is performed in each client and not a central server.

The role of the central server is performed by the simple node app included in this bundle which just relays the WOOT messages to all connected clients using socket.io.

Installation
------------

See examples folder. Copy JS files to your project. Include them in the head and instantiate the adapter like so:

    $(document).ready(function(){
        socket = io.connect( "http://localhost:8000", { "force new connection": true } );
        socket.on('connect', function(){
            window.q = new Woot.TextareaAdapter(socket, '#editor', '#authors')
        });
    });

`#editor` is the editor instance and `#authors` can be div to show all currently connected authors.

Similarly, you can connect the Quill rich text editor via the provided adapter in the examples folder. More info about the excellent QuillJS editor [here](http://quilljs.com/).

You will also need to run the node app or plug it into your own node app. Example assumes that node app is running on `localhost`, port 8000.

Running the example
-------------------

First, run the Node server:

1. `cd node`
2. `npm install`
3. `npm run dev`

Then, run a web server in the example directory. e.g., using [http-server](https://github.com/indexzero/http-server)

1. `npm install -g http-server`
2. `cd example`
3. `http-server`

Finally, open http://localhost:8080 in a couple of browser windows and play!

Compilation
-----------

Sources can be compiled using coffeescript compiler. They are self-contained without outside dependencies.

Known Issues
------------

TextareaAdapter has rudimentary support in terms of user operations currently - adding text via text entry and deleting text via backspace/delete keys. Selection deletes, replaces, copy-paste operations are not supported in TextareaAdapter yet.

Copyright © 2014 Victor Emanouilov, released under the MIT license
