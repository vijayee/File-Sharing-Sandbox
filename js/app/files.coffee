db= level('files')
console.log(db)
db.open ->
  console.log('db is open for business')
class HydraFile
  chunkSize:1000
  blockSize: 16
  file: null
  constructor:(@config) ->
    _.bindAll(@,'receivedFromDb')
    #$.extend(@, @config.File)
    @manifest={name:@config.Name, size: @config.Size,  lastModifiedDate:@config.LastModifiedDate, type:@config.Type, content:[]}
  retrieveManifest:->
    n=0
    b=0
    for i in [0..@config.File.byteLength] by @chunkSize
      chunk=
        id: n
        block: b
        start: i
        end: i + @chunkSize
        key:String(@manifest.name + '-' + @manifest.lastModifiedDate + '-block-' + b + '-' + 'chunk-' + n++)
      @manifest.content.push(chunk)
      db.put chunk.key, @config.File.slice(i, i + @chunkSize), (err)->
        console.error('Failed to store chunk!', err) if err
      @manifest.content.blocks= b+1
      b++ if n % @blockSize == 0
    @manifest
  createFileFromDB:->
    for chunk in @manifest.content
      db.get chunk.key, @receivedFromDb
  createFileFromDBByBlock:->
    for block in [0...@manifest.content.blocks]
      manifestBlock= _.where(@manifest.content, {block: block})
      console.log(manifestBlock)
      options=
        start:manifestBlock[0].key
        end:manifestBlock[manifestBlock.length-1].key
      that= @
      db..createReadStream(options).on 'data',(data) ->
        that.receivedFromDb(null,data.value,data.key)
  receivedFromDb: (err, value, key)->
    if  not @file?
      @file= []
      @file.push(value)
    else
      @file.push(value)
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
      afile= e.target.result
      hydraFile= new HydraFile({Name: file.name, Type: file.type, Size: file.size, LastModifiedDate: file.lastModifiedDate, File: e.target.result})
      console.log(hydraFile.retrieveManifest())
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
 hydraFile.createFileFromDBByBlock()
 #hydraFile.createFileFromDB()
 setTimeout(->
   console.log()
   output= new FileReader
   output.onload= (e)->
     $('#file').after($('<img src="' + e.target.result + '">'))
   output.readAsDataURL(hydraFile.getFile())
 , 1000)

$('#file').on('change', fileChange)
$('#RetrieveFromDB').on('click', retrieveFromDB)
$('#SaveButton').on('click', keyAdded)


