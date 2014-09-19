require 'remote_syslog_logger/syslog_sender'
require 'socket'
require 'openssl'

module RemoteSyslogLogger
  class TcpSslSender < TcpSender
    def initialize(remote_hostname, remote_port, options = {})
      super(remote_hostname, remote_port, options)

      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.set_params verify_mode: options[:ssl_verify_mode] || OpenSSL::SSL::VERIFY_PEER
      ssl_context.ssl_version = :TLSv1_2

      @socket = OpenSSL::SSL::SSLSocket.new(@socket, ssl_context)
      @socket.connect
    end
  end
end
