require 'remote_syslog_logger/syslog_sender'
require 'socket'

module RemoteSyslogLogger
  class TcpSender < SyslogSender
    def initialize(remote_hostname, remote_port, options = {})
      super(remote_hostname, remote_port, options)
      @socket = TCPSocket.open(remote_hostname, remote_port)
    end

    def send_message(content)
      @socket.puts content
    end

    def close
      @socket.close
    end
  end
end
