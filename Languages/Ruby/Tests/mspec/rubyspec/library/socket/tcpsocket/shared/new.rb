require File.dirname(__FILE__) + '/../../../../spec_helper'
require File.dirname(__FILE__) + '/../../fixtures/classes'

describe :tcpsocket_new, :shared => true do
  before :each do
    @hostname = Socket.getaddrinfo("127.0.0.1", nil)[0][2]
  end
  it "requires a hostname and a port as arguments" do
    lambda { TCPSocket.send(@method) }.should raise_error(ArgumentError)
  end

  it "refuses the connection when there is no server to connect to" do
    lambda { TCPSocket.send(@method, '127.0.0.1', SocketSpecs.port) }.should raise_error(Errno::ECONNREFUSED)
  end

  it "connects to a listening server" do
    thread = Thread.new do
      server = TCPServer.new(SocketSpecs.port)
      conn = server.accept
      conn.recv(50)
      conn.close
      server.close
    end
    Thread.pass while thread.status and thread.status != 'sleep'
    thread.status.should_not be_nil
    lambda {
      sock = TCPSocket.send(@method, @hostname, SocketSpecs.port)
      sock.close
    }.should_not raise_error(Errno::ECONNREFUSED)
    thread.join
  end

  it "has an address once it has connected to a listening server" do
    thread = Thread.new do
      server = TCPServer.new('127.0.0.1', SocketSpecs.port)
      conn = server.accept
      conn.recv(50)
      conn.close
      server.close
    end
    Thread.pass while thread.status and thread.status != 'sleep'
    thread.status.should_not be_nil
    sock = TCPSocket.send(@method, '127.0.0.1', SocketSpecs.port)
    sock.addr[0].should == "AF_INET"
    sock.addr[1].should be_kind_of(Fixnum)
    # on some platforms (Mac), MRI
    # returns comma at the end. Other
    # platforms such as OpenBSD setup the
    # localhost as localhost.domain.com
    sock.addr[2].should =~ /^#{@hostname}/
    sock.addr[3].should == "127.0.0.1"
    sock.close
    thread.join
  end

  it "allows local_port to be 0 when local_host is not specified" do
    @thread = SocketSpecs.start_tcp_server('127.0.0.1')
    sock = TCPSocket.new('127.0.0.1', SocketSpecs.port, 0)
    sock.addr[0].should == "AF_INET"
    sock.close
  end

  it "requires local_port to be 0 when local_host is not specified" do
    # The requested address is not valid in its context
    lambda { sock = TCPSocket.new('127.0.0.1', SocketSpecs.port, 1) }.should raise_error(Errno::ENETDOWN)
  end
end
