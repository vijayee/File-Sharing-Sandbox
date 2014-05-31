db= level('./files')
class HydraFile
  chunkSize:1000
  blockSize: 1
  constructor:(@config) ->
    #$.extend(@, @config.File)
    @manifest={name:@config.File.name, size: @config.Filesize,  lastModifiedDate:@config.File.lastModified, type:@config.File.type, content:[]}
  retrieveManifest:->
    n=0
    for i in [0..@config.File.size] by @chunkSize
      chunk=
        id: n++
        start: i
        end: i + @chunkSize
        blob: @config.File.slice(i, i + @chunkSize)
      @manifest.content.push(chunk)
    @manifest


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

fileChange= (e)->
  files=e.target.files
  blobArray=[]
  resultArray=[]
  contentType=""
  afile
  for file in files
    afile= file
    hydraFile= new HydraFile({File: file})
    console.log(hydraFile)
    console.log(hydraFile.retrieveManifest())

    for content in hydraFile.manifest.content
      reader= new FileReader
      reader.onload= (e) ->
        #$('#file').after($('<p>' + e.target.result + '</p>'))
        resultArray.push(e.target.result)
        sendData(e.target.result)
      reader.readAsArrayBuffer(content.blob)
  setTimeout( ->
    console.log("result array: ", resultArray.length)
    blob = new Blob(dataArray, {type:contentType})
    #$.extend(afile, blob)
    output= new FileReader
    output.onload= (e)->
      $('#file').after($('<img src="' + e.target.result + '">'))
    output.readAsDataURL(blob)
  ,2000
  )
keyAdded= ->


$('#file').on('change', fileChange)

$('#SaveButton').on('click', keyAdded)


