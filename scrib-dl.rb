require 'net/http'
require 'json'
require 'open-uri'
require 'uri'
require "shellwords"
require 'httparty'


Ngn = Struct.new(:image_links, :images_downloaded, :links_downloaded,:images_to_download, :lnk, :links_array,:param, :path, :folder_name, :step)
$engine = Ngn.new( )
param_err_msg = "Usage : scrib-dl [link] or [option] [url]\n\n \bOptions: \n\n-a File ------ File containing URLs to download.\n\n"

def init()
	$engine.image_links = Array.new
	$engine.links_array = Array.new
	$engine.images_downloaded = 0;
	$engine.links_downloaded = 1;
	$engine.images_to_download = 0;
	$engine.lnk = nil
	$engine.param = nil
	$engine.path = nil
	$engine.folder_name = nil
	$engine.step = 80
end

def convert_path(path)
	if (path.size() == 0)
		print "Path is not valid"
		exit
	elsif( path.match(/^.\//) )
		path.slice!(0)
		return Shellwords.escape(Dir.pwd.to_s+path.to_s)
	end

	current_directory = Shellwords.escape(Dir.pwd).split("/")
	rtv_path_array = path.split("/")
	steps_back  = rtv_path_array.size() - 1
	if( steps_back >= ( current_directory.size() -1 ) )
		return Shellwords.escape("/"+(rtv_path_array[rtv_path_array.size() - 1]).to_s)
	else
		cp = current_directory.size() - steps_back -1
		tmp_path = "/"
		for i in 0..cp
			tmp_path += current_directory[i].to_s
			if( i != 0)
				tmp_path += "/"
			end
		end
		return Shellwords.escape(tmp_path.to_s+rtv_path_array[steps_back].to_s)
	end
end

def read_file(file_path)
	links = Array.new
	begin
		file = File.new(file_path, "r")
		while (line = file.gets)
		    links.push(line)
		end
		file.close
	rescue => err
		print "Exception #{err}"
	end
	return links
end

def loader(label, val)
	if val == 0
		val = 1
	end
	 print "\r"
	 arrows = val / 3
	 print"#{label} #{val}%  [["
	 for i in 0..arrows
	 	if ( i > 0 )
	 		print "\b\b"
	 		print ">]]"
	 	elsif
	 		print ">]]"
	 	end
	 end
end

def download_image( url ) 
	if (url.size() != 0)
		name = []
		name = url.scan(/\/images\/(\d{0,})-/)[0][0]
		if(name =~ /\d/ )
			open(url) {|f|
		  	File.open("#{$engine.folder_name}/#{name}.jpg","wb") do |file|
		    	file.puts f.read
		    end		
	    }	
		else
			puts "Error url: #{url}"
		end 
	end 		
end				

def get_containt( url )
	begin
		uri = URI.parse(URI::encode(url))
		# request = Net::HTTP::Get.new(url)
		# http = Net::HTTP.new(uri.host, uri.port)
		res = HTTParty.get(uri)
		print res.code
		return  res
		# return  http.request(request)
	rescue => err
		puts "Exception #{err} \n"+url.to_s
	end
end

def copy_array(ar) 
	tmp = []
	for item in ar 
		tmp.push(item)
	end
	return tmp
 end

def download_lnk(lnks_array)
	threads = []
	tmp_array = copy_array(lnks_array)
	for i in 0..(lnks_array.size() - 1 )
		threads.push( Thread.new {
			link = tmp_array.pop()
			name = link.scan(/pages\/(\d{0,})-/)[0][0]
			$engine.links_downloaded += 1
			if( !File.exist?("#{$engine.folder_name}/#{name}.jpg") )
				content = get_containt(link.sub('https', 'http')).body
		   		img = content.scan( /(http:\/\/[\w|\d|\.|\/|-]{1,}.jpg)/ )
			   	if( img.size() > 0 )
			   		$engine.image_links.push(img[0][0])
			 	else
			 		# puts "Link is null."
	 			end
	 		else
	 			$engine.images_downloaded +=1
			end
		})
		loader("Download Links:", $engine.links_downloaded * 100 / $engine.links_array.size())
	end
	threads.each { |w| w.join }
end

def dwnl_bp(img_array)
	threads = []
	for i in 0..img_array.size() - 1 do
		threads.push( Thread.new { 
			tmp = img_array.pop()
			if(tmp.size() > 0 && tmp)
				download_image(tmp) 
				$engine.images_downloaded  += 1
				loader("Download book pages:", $engine.images_downloaded * 100 / $engine.images_to_download);
			end
		})
	end
	threads.each { |w| w.join  }
end

def break_array(start, stop, array, mode)# mode 1 download links, mode 2 download images
	items_array = Array.new
	lng = stop - start
	for x in 0..lng
		item = array[start] 
		if(item)
			items_array[x] = item
		end
		start += 1
	end
	if mode == 1
		download_lnk(items_array)
	elsif mode == 2
		dwnl_bp(items_array)
	end
end

def thread_p( array, mode )
	flag = true 
	start = 0 
	stp = $engine.step 
	stop = stp - 1
	lnk_array_s = array.size()
	while(flag) do
		if(stp > lnk_array_s)
			stop = lnk_array_s - 1
		end
		break_array(start, stop, array, mode)
		start = stop +1
		stop += stp
		if(stop > lnk_array_s)
			start = stop - stp + 1
			stop = lnk_array_s - 1
			break_array(start, stop, array, mode)
			flag = false
		end
	end
end

def main()
	if ($engine.lnk)
		begin
			print "\nBook: #{URI.decode($engine.lnk).scan(/\d\/(.{1,})/)[0][0]}\n"
			$engine.folder_name = URI.decode($engine.lnk).scan(/\d\/(.{1,})/)[0][0]
		rescue StandardError => err
			print "\nError: url is not valid\n"
		end
		
	else
		print "\nPlease insert a valid link. " +err.to_s+"\n"
	end

		#Create folder
	if(!File.directory?($engine.folder_name))
		Dir.mkdir($engine.folder_name)
	end

	response = get_containt($engine.lnk);
	if response.code.to_i == 200
		print "\nHtml content downloaded success\n"
	else
		print "\nError - cant open url!\n"
		exit
	end	
	
	$engine.links_array =  response.body.scan(/http.:\/\/.{1,}.jsonp/) #links
	first_pages = response.body.scan( /(http:\/\/.{1,}.jpg)/)
	for ur  in first_pages do
		$engine.image_links.push(ur[0])
	end
	$engine.images_to_download = $engine.links_array.size()
	thread_p($engine.links_array, 1)
	loader("Download Links:", 100)
	print "\n"
	thread_p($engine.image_links, 2)
	loader("Download book pages:", 100)
end

if(ARGV.size() == 2)
	links = Array.new
	if (ARGV[0] != "-a")
		print "\nWrong parameter.\n#{param_err_msg}\n"
		exit
	end
	$engine.path = ARGV[ARGV.size() - 1]
	$engine.param = ARGV[0]
	links = read_file(convert_path($engine.path).to_s)
	for lnk in links
		init()
		$engine.lnk = lnk
		main()
		print "\n"
	end
elsif(ARGV.size() > 2)
	print param_err_msg
	exit
else
	init()
	$engine.lnk = ARGV[0].dup.force_encoding("UTF-8")	
	main()
	print "\nDownload complete\n"
end
