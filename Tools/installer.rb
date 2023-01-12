#!/usr/bin/env ruby -wKU

###################################################################
# make an installer for Soundflower
# requires: you must have already performed a Deployment build and
# thus have the kext installed to /System/Library/Extensions
###################################################################

require 'open3'
require 'fileutils'
require 'pathname'
require 'rexml/document'
include REXML

# This finds our current directory, to generate an absolute path for the require
libdir = "."
Dir.chdir libdir        # change to libdir so that requires work

@svn_root = ".."
@version = "9.9.9"

Dir.chdir @svn_root
@svn_root = Dir.pwd


###################################################################
# sub routines
###################################################################

def create_logs
  @build_log = File.new("#{@svn_root}/Installer/_installer.log", "w")
  @build_log.write("SOUNDFLOWER INSTALLER LOG: #{`date`}\n\n")
  @build_log.flush
  @error_log = File.new("#{@svn_root}/Installer/_error.log", "w")
  @error_log.write("SOUNDFLOWER INSTALLER ERROR LOG: #{`date`}\n\n")
  @error_log.flush
  trap("SIGINT") { die }
end
  
def die
  close_logs
  exit 0
end

def close_logs
  @build_log.close
  @error_log.close
end

def log_build(str)
  @build_log.write(str)
  @build_log.write("\n\n")
  @build_log.flush
end

def log_error(str)
  @error_log.write(str)
  @error_log.write("\n\n")
  @error_log.flush
end


# This defines a wrapper that we use to call shell commands
def cmd(commandString)
  out = ""
  err = ""
  
  Open3.popen3(commandString) do |stdin, stdout, stderr|
    out = stdout.read
    err = stderr.read
  end
  log_error(out)
  log_error(err)
end


def getversion()
  theVersion = "0.0.0"

  f = File.open("/System/Library/Extensions/Soundflower.kext/Contents/Info.plist", "r")
  str = f.read
  theVersion = str.match(/<key>CFBundleShortVersionString<\/key>\n.*<string>(.*)<\/string>/).captures[0]
  f.close
  
  puts"  version: #{theVersion}"
  return theVersion;
end

###################################################################
# here is where we actually build the installer
###################################################################

create_logs()
@version = getversion()

@build_folder = "#{@svn_root}/Build/Soundflower-#{@version}"

puts "  Creating installer directory structure..."
cmd("rm -rfv \"#{@build_folder}\"")                       # remove an old temp dir if it exists
cmd("mkdir -pv \"#{@build_folder}\"")                     # now make a clean one, and build dir structure in it

puts "  Building Package -- this could take a while..."
cmd("rm -rfv \"#{@svn_root}/Installers/Soundflower.pkg\"")
#cmd("/Developer/usr/bin/packagemaker --verbose --root \"#{@svn_root}/Installer/root\" --id com.cycling74.soundflower --out \"#{@svn_root}/Installer/Soundflower/Soundflower.pkg\" --version #{@version} --title Soundflower --resources \"#{@svn_root}/Installer/Resources\" --target 10.4 --domain system --root-volume-only")
cmd("/Developer/usr/bin/packagemaker --verbose --doc \"#{@svn_root}/Installer/Soundflower.pmdoc\" --out \"#{@build_folder}/Soundflower.pkg\" ")

puts "  Copying readme, license, etc...."
cmd("cp \"#{@svn_root}/License.txt\" \"#{@build_folder}\"")
cmd("cp \"#{@svn_root}/Installer/ReadMe.rtf\" \"#{@build_folder}\"")
cmd("cp \"#{@svn_root}/Tools/Uninstall Soundflower.scpt\" \"#{@build_folder}\"")

puts "  Creating Disk Image..."
cmd("rm -rfv \"#{@svn_root}/Installer/Soundflower-#{@version}.dmg\"")
cmd("hdiutil create -srcfolder \"#{@build_folder}\" \"#{@svn_root}/Build/Soundflower-#{@version}.dmg\"")

puts "  All done!"

close_logs
puts ""
exit 0
