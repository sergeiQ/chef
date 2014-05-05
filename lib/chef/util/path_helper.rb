#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/platform'
require 'chef/exceptions'

class Chef
  class Util
    class PathHelper
      # Maximum characters in a standard Windows path (260 including drive letter and NUL)
      WIN_MAX_PATH = 259

      def self.valid_path?(path, warn=false, error=false)
        valid_path = true

        if Chef::Platform.windows?
          unless printable?(path)
            msg = "Path '#{path}' contains non-printable characters. Check that backslashes are escaped with another backslash (e.g. C:\\\\Windows) in double-quoted strings."
            Chef::Log.warn(msg) if warn
            raise Chef::Exceptions::ValidationFailed, msg if error
            valid_path = false
          end
            
          if windows_max_length_exceeded?(path)
            msg = "Path '#{path}' is longer than #{WIN_MAX_PATH}, and therefore must be prefexed with '\\\\?\\'"
            Chef::Log.warn(msg) if warn
            raise Chef::Exceptions::ValidationFailed, msg if error
            valid_path = false
          end
        end
      
        valid_path
      end

      def self.windows_max_length_exceeded?(path)
        # Check to see if paths without the \\?\ prefix are over the maximum allowed length for the Windows API
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
        unless path =~ /^\\\\?\\/
          if path.length > WIN_MAX_PATH
            return true
          end
        end
        
        false
      end

      def self.native_path(path)
        # ALT_SEPARATOR is \\ on windows, nil on linux
        if ::File::ALT_SEPARATOR
          # Windows API calls often require an absolute path using backslashes, e.g. "C:\Program Files (x86)\Microsoft Office"
          canonical_path(path).gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR)
        else
          canonical_path(path)
        end
      end

      def self.printable?(string)
        # returns true if string is free of non-printable characters (escape sequences)
        # this returns false for whitespace escape sequences as well, e.g. \n\t
        if string =~ /[^[:print:]]/
          false
        else
          true
        end
      end

      # Produce a comparable path. File.absolute_path does this for us.
      # This conveniently matches the case for filenames on Windows as well.
      def self.canonical_path(path)
        File.absolute_path(path)
      end

      def self.paths_eql?(path1, path2)
        canonical_path(path1) == canonical_path(path2)
      end
    end
  end
end
