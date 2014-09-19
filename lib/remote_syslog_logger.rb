require 'remote_syslog_logger/udp_sender'
require 'remote_syslog_logger/tcp_sender'
require 'remote_syslog_logger/tcp_ssl_sender'
require 'logger'

module RemoteSyslogLogger
  VERSION = '1.0.3'

  # creates a new logger that logs messages to a remote syslog server
  #
  # specify a transmission protocol with options[:protocol] (defaulting to :udp):
  #
  #   :udp Insecure UDP broadcasts
  #   :tcp Insecure TCP delivery
  #   :tcp_ssl Secure TCP delivery inside an SSL socket
  #
  def self.new(remote_hostname, remote_port, options = {})
    case options[:protocol] || :udp
      when :udp
        Logger.new(RemoteSyslogLogger::UdpSender.new(remote_hostname, remote_port, options))
      when :tcp
        Logger.new(RemoteSyslogLogger::TcpSender.new(remote_hostname, remote_port, options))
      when :tcp_ssl
        Logger.new(RemoteSyslogLogger::TcpSslSender.new(remote_hostname, remote_port, options))
    end
  end
end