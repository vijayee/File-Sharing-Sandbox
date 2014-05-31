// Generated by CoffeeScript 1.7.1
(function() {
  var HydraFile, closeDataChannels, createConnection, dataArray, db, fileChange, gotLocalCandidate, gotLocalDescription, gotReceiveChannel, gotRemoteDescription, gotRemoteIceCandidate, handleMessage, handleReceiveChannelStateChange, handleSendChannelStateChange, keyAdded, sendData;

  db = level('./files');

  HydraFile = (function() {
    HydraFile.prototype.chunkSize = 1000;

    HydraFile.prototype.blockSize = 1;

    function HydraFile(config) {
      this.config = config;
      this.manifest = {
        name: this.config.File.name,
        size: this.config.Filesize,
        lastModifiedDate: this.config.File.lastModified,
        type: this.config.File.type,
        content: []
      };
    }

    HydraFile.prototype.retrieveManifest = function() {
      var chunk, i, n, _i, _ref, _ref1;
      n = 0;
      for (i = _i = 0, _ref = this.config.File.size, _ref1 = this.chunkSize; _ref1 > 0 ? _i <= _ref : _i >= _ref; i = _i += _ref1) {
        chunk = {
          id: n++,
          start: i,
          end: i + this.chunkSize,
          blob: this.config.File.slice(i, i + this.chunkSize)
        };
        this.manifest.content.push(chunk);
      }
      return this.manifest;
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

  fileChange = function(e) {
    var afile, blobArray, content, contentType, file, files, hydraFile, reader, resultArray, _i, _j, _len, _len1, _ref;
    files = e.target.files;
    blobArray = [];
    resultArray = [];
    contentType = "";
    afile;
    for (_i = 0, _len = files.length; _i < _len; _i++) {
      file = files[_i];
      afile = file;
      hydraFile = new HydraFile({
        File: file
      });
      console.log(hydraFile);
      console.log(hydraFile.retrieveManifest());
      _ref = hydraFile.manifest.content;
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        content = _ref[_j];
        reader = new FileReader;
        reader.onload = function(e) {
          resultArray.push(e.target.result);
          return sendData(e.target.result);
        };
        reader.readAsArrayBuffer(content.blob);
      }
    }
    return setTimeout(function() {
      var blob, output;
      console.log("result array: ", resultArray.length);
      blob = new Blob(dataArray, {
        type: contentType
      });
      output = new FileReader;
      output.onload = function(e) {
        return $('#file').after($('<img src="' + e.target.result + '">'));
      };
      return output.readAsDataURL(blob);
    }, 2000);
  };

  keyAdded = function() {};

  $('#file').on('change', fileChange);

  $('#SaveButton').on('click', keyAdded);

}).call(this);

//# sourceMappingURL=files.map