module Gitlab
  module Metrics
    # Module for gathering system/process statistics such as the memory usage.
    #
    # This module relies on the /proc filesystem being available. If /proc is
    # not available the methods of this module will be stubbed.
    module System
      if File.exist?('/proc')
        # Returns the current process' memory usage in bytes.
        def self.memory_usage
          mem   = 0
          match = File.read('/proc/self/status').match(/VmRSS:\s+(\d+)/)

          if match && match[1]
            mem = match[1].to_f * 1024
          end

          mem
        end

        def self.file_descriptor_count
          Dir.glob('/proc/self/fd/*').length
        end
      else
        def self.memory_usage
          0.0
        end

        def self.file_descriptor_count
          0
        end
      end

      # THREAD_CPUTIME is not supported on OS X
      if Process.const_defined?(:CLOCK_THREAD_CPUTIME_ID)
        def self.cpu_time
          Process
            .clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID, :millisecond)
        end
      else
        def self.cpu_time
          Process
            .clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID, :millisecond)
        end
      end

      # Returns the current real time in a given precision.
      #
      # Returns the time as a Fixnum.
      def self.real_time(precision = :millisecond)
        Process.clock_gettime(Process::CLOCK_REALTIME, precision)
      end

      # Returns the current monotonic clock time in a given precision.
      #
      # Returns the time as a Fixnum.
      def self.monotonic_time(precision = :millisecond)
        Process.clock_gettime(Process::CLOCK_MONOTONIC, precision)
      end
    end
  end
end
