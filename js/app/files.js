// Generated by CoffeeScript 1.7.1
(function() {
  var HydraFile, closeDataChannels, createConnection, dataArray, db, fileChange, gotLocalCandidate, gotLocalDescription, gotReceiveChannel, gotRemoteDescription, gotRemoteIceCandidate, handleMessage, handleReceiveChannelStateChange, handleSendChannelStateChange, hydraFile, keyAdded, retrieveFromDB, sendData;

  db = level('files');

  db.open(function() {
    return console.log('db is open for business');
  });

  HydraFile = (function() {
    HydraFile.prototype.chunkSize = 1000;

    HydraFile.prototype.blockSize = 1;

    HydraFile.prototype.file = null;

    function HydraFile(config) {
      this.config = config;
      _.bindAll(this, 'receivedFromDb');
      this.manifest = {
        name: this.config.Name,
        size: this.config.Size,
        lastModifiedDate: this.config.LastModifiedDate,
        type: this.config.Type,
        content: []
      };
    }

    HydraFile.prototype.retrieveManifest = function() {
      var chunk, i, n, _i, _ref, _ref1;
      n = 0;
      for (i = _i = 0, _ref = this.config.File.byteLength, _ref1 = this.chunkSize; _ref1 > 0 ? _i <= _ref : _i >= _ref; i = _i += _ref1) {
        chunk = {
          id: n,
          start: i,
          end: i + this.chunkSize,
          blob: this.config.File.slice(i, i + this.chunkSize),
          key: String(this.manifest.name + '-' + this.manifest.lastModifiedDate + '-' + 'chunk-' + n++)
        };
        this.manifest.content.push(chunk);
        db.put(chunk.key, chunk.blob, function(err) {
          if (err) {
            return console.error('Failed to store chunk!', err);
          }
        });
      }
      return this.manifest;
    };

    HydraFile.prototype.createFileFromDB = function() {
      var chunk, _i, _len, _ref, _results;
      _ref = this.manifest.content;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chunk = _ref[_i];
        _results.push(db.get(chunk.key, this.receivedFromDb));
      }
      return _results;
    };

    HydraFile.prototype.receivedFromDb = function(err, value, key) {
      var appendBuffer;
      appendBuffer = function(buffer1, buffer2) {
        var tmp;
        tmp = new Uint8Array(buffer1.byteLength + buffer2.byteLength);
        tmp.set(new Uint8Array(buffer1), 0);
        tmp.set(new Uint8Array(buffer2), buffer1.byteLength);
        return tmp.buffer;
      };
      if (err) {
        console.error('Failed to retrieve chunk!', err);
      }
      console.log(key);
      console.log(value);
      if (this.file == null) {
        return this.file = value;
      } else {
        return this.file = appendBuffer(file, value);
      }
    };

    HydraFile.prototype.getFile = function() {
      return new Blob(this.file);
    };

    return HydraFile;

  })();

  createConnection = function() {
    var e;
    window.localPeerConnection = new webkitRTCPeerConnection(null, {
      optional: []
    });
    window.remotePeerConnection = new webkitRTCPeerConnection(null, {
      optional: []
    });
    console.log('Created remote peer connection object remotePeerConnection');
    remotePeerConnection.onicecandidate = gotRemoteIceCandidate;
    remotePeerConnection.ondatachannel = gotReceiveChannel;
    console.log("remotepeerconnection: ", remotePeerConnection);
    try {
      window.sendChannel = localPeerConnection.createDataChannel("sendDataChannel", {
        reliable: false
      });
      console.log('Created send data channel');
    } catch (_error) {
      e = _error;
      alert('Failed to create data channel. You need Chrome M25 or later with RtpDataChannel enabled');
      console.log('createDataChannel() failed with exception: ' + e.message);
    }
    localPeerConnection.onicecandidate = gotLocalCandidate;
    sendChannel.onopen = handleSendChannelStateChange;
    sendChannel.onclose = handleSendChannelStateChange;
    return localPeerConnection.createOffer(gotLocalDescription);
  };

  sendData = function(data) {
    return sendChannel.send(data);
  };

  closeDataChannels = function() {
    var localPeerConnection, remotePeerConnection;
    console.log('Closing data channels');
    sendChannel.close();
    console.log('Closed data channel with label: ' + sendChannel.label);
    receiveChannel.close();
    console.log('Closed data channel with label: ' + receiveChannel.label);
    localPeerConnection.close();
    remotePeerConnection.close();
    localPeerConnection = null;
    remotePeerConnection = null;
    return console.log('Closed peer connections');
  };

  gotLocalDescription = function(desc) {
    localPeerConnection.setLocalDescription(desc);
    console.log('Offer from localPeerConnection \n' + desc.sdp);
    remotePeerConnection.setRemoteDescription(desc);
    return remotePeerConnection.createAnswer(gotRemoteDescription);
  };

  gotRemoteDescription = function(desc) {
    remotePeerConnection.setLocalDescription(desc);
    console.log('Answer from remotePeerConnection \n' + desc.sdp);
    return localPeerConnection.setRemoteDescription(desc);
  };

  gotLocalCandidate = function(event) {
    console.log('local ice callback');
    if (event.candidate) {
      remotePeerConnection.addIceCandidate(event.candidate);
      return console.log('Local ICE candidate: \n' + event.candidate.candidate);
    }
  };

  gotReceiveChannel = function(event) {
    var receiveChannel;
    console.log('Receive Channel Callback');
    receiveChannel = event.channel;
    receiveChannel.onmessage = handleMessage;
    receiveChannel.onopen = handleReceiveChannelStateChange;
    return receiveChannel.onclose = handleReceiveChannelStateChange;
  };

  gotRemoteIceCandidate = function(event) {
    console.log('remote ice callback');
    if (event.candidate) {
      localPeerConnection.addIceCandidate(event.candidate);
      return console.log('Remote ICE candidate: \n ' + event.candidate.candidate);
    }
  };

  dataArray = [];

  handleMessage = function(event) {
    return dataArray.push(event.data);
  };

  gotReceiveChannel = function(event) {
    console.log('Receive Channel Callback');
    window.receiveChannel = event.channel;
    receiveChannel.onmessage = handleMessage;
    receiveChannel.onopen = handleReceiveChannelStateChange;
    return receiveChannel.onclose = handleReceiveChannelStateChange;
  };

  handleSendChannelStateChange = function() {
    var readyState;
    readyState = sendChannel.readyState;
    return console.log('Send channel state is: ' + readyState);
  };

  handleReceiveChannelStateChange = function() {
    var readyState;
    console.log(receiveChannel);
    readyState = receiveChannel.readyState;
    return console.log('Receive channel state is: ' + readyState);
  };

  createConnection();

  hydraFile = null;

  fileChange = function(e) {
    var afile, blobArray, contentType, file, files, reader, resultArray, _i, _len, _results;
    files = e.target.files;
    blobArray = [];
    resultArray = [];
    contentType = "";
    afile = null;
    _results = [];
    for (_i = 0, _len = files.length; _i < _len; _i++) {
      file = files[_i];
      reader = new FileReader;
      reader.onload = function(e) {
        console.log(e);
        afile = e.target.result;
        hydraFile = new HydraFile({
          Name: file.name,
          Type: file.type,
          Size: file.size,
          LastModifiedDate: file.lastModifiedDate,
          File: e.target.result
        });
        console.log(hydraFile);
        return console.log(hydraFile.retrieveManifest());

        /*
        setTimeout(->
          console.log(hydraFile.getFile())
        ,1000)
         */
      };
      _results.push(reader.readAsArrayBuffer(file));
    }
    return _results;
  };

  keyAdded = function() {
    var document, key, keyHolder, value, valueHolder;
    key = $("#key").val();
    value = $("#value").val();
    db.put(key, value, function(err) {
      if (err) {
        return console.error(err);
      }
    });
    document = $("<ul class='pricing-table'></ul>");
    keyHolder = $("<li class='title'></li>");
    valueHolder = $("<li class='bullet-item'></li>");
    return setTimeout(function() {
      db.get(key, function(err, value, key) {});
      if (typeof err !== "undefined" && err !== null) {
        console.error(err);
      }
      console.log(value);
      keyHolder.val(key);
      valueHolder.val(value);
      document.append(keyHolder.text(key));
      document.append(valueHolder.text(value));
      $('#KeysValues').append(document);
      $("#key").val(null);
      return $("#value").val(null);
    }, 3000);
  };

  retrieveFromDB = function() {
    console.log('happened');
    hydraFile.createFileFromDB();
    return setTimeout(function() {
      return console.log(hydraFile.getFile());
    }, 2000);
  };

  $('#file').on('change', fileChange);

  $('#RetrieveFromDB').on('click', retrieveFromDB);

  $('#SaveButton').on('click', keyAdded);

}).call(this);

//# sourceMappingURL=files.map
