db= level('files')
db.open ->
  console.log('db is open for business')
class HydraFile
  chunkSize:1000
  blockSize: 1
  file: null
  constructor:(@config) ->
    _.bindAll(@,'receivedFromDb')
    #$.extend(@, @config.File)
    @manifest={name:@config.Name, size: @config.Size,  lastModifiedDate:@config.LastModifiedDate, type:@config.Type, content:[]}
  retrieveManifest:->
    n=0
    for i in [0..@config.File.byteLength] by @chunkSize
      chunk=
        id: n
        start: i
        end: i + @chunkSize
        blob: @config.File.slice(i, i + @chunkSize)
        key:String(@manifest.name + '-' + @manifest.lastModifiedDate + '-' + 'chunk-' + n++)
      @manifest.content.push(chunk)
      db.put chunk.key, chunk.blob, (err)->
        console.error('Failed to store chunk!', err) if err
    @manifest
  createFileFromDB:->
    for chunk in @manifest.content
      db.get chunk.key, @receivedFromDb
  receivedFromDb: (err, value, key)->
    appendBuffer=(buffer1, buffer2) ->
      tmp = new Uint8Array(buffer1.byteLength + buffer2.byteLength)
      tmp.set(new Uint8Array(buffer1), 0)
      tmp.set(new Uint8Array(buffer2), buffer1.byteLength)
      tmp.buffer
    console.error('Failed to retrieve chunk!', err) if err
    console.log(key)
    console.log(value)
    #console.log(@)
    if !@file?
      @file= value
    else
      @file= appendBuffer(file,value)
  getFile:->
    new Blob(@file)




createConnection= ->
  window.localPeerConnection = new webkitRTCPeerConnection(null,  {optional: []})
  window.remotePeerConnection = new webkitRTCPeerConnection(null,    {optional: []});
  console.log('Created remote peer connection object remotePeerConnection')
  remotePeerConnection.onicecandidate = gotRemoteIceCandidate
  remotePeerConnection.ondatachannel = gotReceiveChannel
  console.log("remotepeerconnection: ",remotePeerConnection)
  try
    window.sendChannel = localPeerConnection.createDataChannel("sendDataChannel",  {reliable: false})
    console.log('Created send data channel')
  catch e
    alert('Failed to create data channel. You need Chrome M25 or later with RtpDataChannel enabled')
    console.log('createDataChannel() failed with exception: ' + e.message)
  localPeerConnection.onicecandidate = gotLocalCandidate
  sendChannel.onopen = handleSendChannelStateChange
  sendChannel.onclose = handleSendChannelStateChange

  localPeerConnection.createOffer(gotLocalDescription)

sendData= (data)->
  sendChannel.send(data)
  #console.log('Sent data: ' + data)

closeDataChannels= ->
  console.log('Closing data channels')
  sendChannel.close()
  console.log('Closed data channel with label: ' + sendChannel.label)
  receiveChannel.close()
  console.log('Closed data channel with label: ' + receiveChannel.label)
  localPeerConnection.close()
  remotePeerConnection.close()
  localPeerConnection = null
  remotePeerConnection = null
  console.log('Closed peer connections')

gotLocalDescription= (desc) ->
  localPeerConnection.setLocalDescription(desc);
  console.log('Offer from localPeerConnection \n' + desc.sdp)
  remotePeerConnection.setRemoteDescription(desc)
  remotePeerConnection.createAnswer(gotRemoteDescription)

gotRemoteDescription= (desc) ->
  remotePeerConnection.setLocalDescription(desc)
  console.log('Answer from remotePeerConnection \n' + desc.sdp)
  localPeerConnection.setRemoteDescription(desc)

gotLocalCandidate= (event) ->
  console.log('local ice callback')
  if event.candidate
    remotePeerConnection.addIceCandidate(event.candidate)
    console.log('Local ICE candidate: \n' + event.candidate.candidate)

gotReceiveChannel= (event) ->
  console.log('Receive Channel Callback');
  receiveChannel = event.channel;
  receiveChannel.onmessage = handleMessage;
  receiveChannel.onopen = handleReceiveChannelStateChange;
  receiveChannel.onclose = handleReceiveChannelStateChange;


gotRemoteIceCandidate= (event) ->
  console.log('remote ice callback')
  if event.candidate
    localPeerConnection.addIceCandidate(event.candidate)
    console.log('Remote ICE candidate: \n ' + event.candidate.candidate)
dataArray=[]
handleMessage= (event) ->
  #console.log('Received message: ' , event.data)
  dataArray.push(event.data)

gotReceiveChannel= (event) ->
  console.log('Receive Channel Callback')
  window.receiveChannel = event.channel
  receiveChannel.onmessage = handleMessage
  receiveChannel.onopen = handleReceiveChannelStateChange
  receiveChannel.onclose = handleReceiveChannelStateChange

handleSendChannelStateChange= ->
  readyState = sendChannel.readyState;
  console.log('Send channel state is: ' + readyState)


handleReceiveChannelStateChange= ->
  console.log(receiveChannel)
  readyState = receiveChannel.readyState
  console.log('Receive channel state is: ' + readyState)

createConnection()
hydraFile= null
fileChange= (e)->
  files=e.target.files
  blobArray=[]
  resultArray=[]
  contentType=""
  afile=null
  for file in files
    reader= new FileReader
    reader.onload= (e) ->
      console.log(e)
      afile= e.target.result
      hydraFile= new HydraFile({Name: file.name, Type: file.type, Size: file.size, LastModifiedDate: file.lastModifiedDate, File: e.target.result})
      console.log(hydraFile)
      console.log(hydraFile.retrieveManifest())
      #hydraFile.createFileFromDB()
      ###
      setTimeout(->
        console.log(hydraFile.getFile())
      ,1000)

      ###
    reader.readAsArrayBuffer(file)
keyAdded= ->
  key=$("#key").val()
  value=$("#value").val()
  db.put key, value, (err)->
    console.error(err) if err
  document= $("<ul class='pricing-table'></ul>")
  keyHolder= $("<li class='title'></li>")
  valueHolder= $("<li class='bullet-item'></li>")
  setTimeout(->
    db.get key, (err, value, key) ->
    console.error(err) if err?
    console.log(value)
    keyHolder.val(key)
    valueHolder.val(value)
    document.append(keyHolder.text(key))
    document.append(valueHolder.text(value))
    $('#KeysValues').append(document)
    $("#key").val(null)
    $("#value").val(null)
  ,3000)


retrieveFromDB=->
 console.log('happened')
 hydraFile.createFileFromDB()
 setTimeout(->
   console.log(hydraFile.getFile())
 , 2000)

$('#file').on('change', fileChange)
$('#RetrieveFromDB').on('click', retrieveFromDB)
$('#SaveButton').on('click', keyAdded)


