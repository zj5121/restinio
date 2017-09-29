require 'mxx_ru/cpp'

def file_exists?( dir, f )
  fname = File.join( dir, f )
  if File.exist?( fname ) and File.file?( fname )
    fname
  else
    nil
  end
end

def all_files_exist( dir, files )
  not files.find{|f| !file_exists?(dir, f ) }
end

def find_first_openssl_libs( openssl_before_11, openssl_after_11 )

  lib_dirs = ENV[ "LIB" ]
  if lib_dirs

    dirs_to_look = lib_dirs.split( ';' ).select{|p| p != "" }

    dir_indx_before_11 = dirs_to_look.find_index{|d| all_files_exist( d, openssl_before_11 ) }
    dir_indx_after_11 = dirs_to_look.find_index{|d| all_files_exist( d, openssl_after_11 ) }
  end

  if dir_indx_before_11 and dir_indx_after_11
    if dir_indx_after_11 < dir_indx_after_11
      openssl_before_11
    else
      openssl_after_11
    end
  elsif dir_indx_before_11
    openssl_before_11
  elsif dir_indx_after_11
    openssl_after_11
  else
    raise "OpenSSL libs not found; tried [#{openssl_before_11.join(', ')}] and [#{openssl_after_11.join(', ')}]"
  end
end

def get_libs_vc
  find_first_openssl_libs(
    [ 'libeay32.lib', 'ssleay32.lib' ],
    [ 'libssl.lib', 'libcrypto.lib' ] )
end

def get_libs_linux
  [ 'ssl', 'crypto' ]
end

def get_libs_mingw
  get_libs_linux + [ 'gdi32' ]
end


def get_libs
  if 'mswin' == toolset.tag( 'target_os' )
      if 'vc' == toolset.name
        get_libs_vc
      elsif 'gcc' == toolset.name
        get_libs_mingw
      end
  else
    get_libs_linux
  end
end

MxxRu::Cpp::lib_collection_target {
  custom_local_openssl_prj = ENV[ "OPENSSL_PRJ_FILE" ]
  if custom_local_openssl_prj.nil?
    custom_local_openssl_prj = 'local-openssl.rb'
  else
    if not File.exist?( custom_local_openssl_prj )
      raise "unable to locate file #{custom_local_openssl_prj}"
    end
  end

  if File.exist?( custom_local_openssl_prj )
    required_prj custom_local_openssl_prj
  else
    get_libs.each{|l| lib(l)}
  end
}

if __FILE__ == $0
	libs = get_libs
	if libs
		puts "Openssl libs: #{libs.join(', ')}"
	else
		puts "Openssl libs not found"
	end
end
