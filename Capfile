#### Congfiguration ####

require 'catpaws/ec2'
require 'pathname'

set :aws_access_key,  ENV['AMAZON_ACCESS_KEY']
set :aws_secret_access_key , ENV['AMAZON_SECRET_ACCESS_KEY']
set :ec2_url, ENV['EC2_URL']
set :key, ENV['EC2_KEY'] #this should be the name of the key in aws, not the actual keyfile
set :ssh_options, {
  :keys => [ENV['EC2_KEYFILE']],
  :user => "ubuntu"
}
set :ami, 'ami-52794c26' #32-bit ubuntu lucid server (eu-west-1)
set :instance_type, 'm1.small'
set :s3cfg, ENV['S3CFG'] #location of ubuntu s3cfg file
set :working_dir, '/mnt/work'

set :group_name, 'pasquale_DNRest_illumina'
set :nhosts, 1

set :snap_id, `cat SNAPID`.chomp #empty until you've created a snapshot
set :vol_id, `cat VOLUMEID`.chomp #empty until you've created a new volume
set :ebs_size, 2  #We really don't need a lot of space for a basic differential expression study
set :availability_zone, 'eu-west-1a'  #wherever your ami is
set :dev, '/dev/sdf'
set :mount_point, '/mnt/data'


# Try and load a local config file to override any of the above values, should one exist.
# So that if you change these values, they don't get overwritten if you update the repos.
begin
 load("Capfile.local")
rescue Exception
end

#cap EC2:start
#cap EBS:create (unless you want to use the one that already exists)
#cap EBS:attach
#cap EBS:format_xfs
#cap EBS:mount_xfs
#
# cap git_clone
# cap install_r
# cap install_s3
# 
#cap EBS:snapshot
#cap EBS:unmount
#cap EBS:detach
#cap EBS:delete
#cap EC2:stop

#### Tasks ####



desc "About this project"
task :about, :hosts => 'localhost' do
  puts <<eos
 Project:      REST/NRSF in Astrocytes
 Experiment:   Expression data from astrocytes infected with Dom-Neg Rest vs Empty Vector
 Publication:  
 Author:       Manuela Volta
 Author:       Chiara Soldati
 Author:       Cass Johnston
 Author:       Noel Buckley
 Contact:      Cass Johnston 
 Email:        caroline.johnston@kcl.ac.uk
eos
end
  

desc "install R on all running instances in group group_name"
task :install_r, :roles  => group_name do
  user = variables[:ssh_options][:user]
  sudo 'apt-get update'
  sudo 'apt-get -y install r-base'
  sudo 'apt-get -y install build-essential libxml2 libxml2-dev libcurl3 libcurl4-openssl-dev'
  upload("scripts/R_setup.R", "#{working_dir}/R_setup.R")
  run "cd #{working_dir} && chmod +x R_setup.R"
  sudo "Rscript #{working_dir}/R_setup.R"
end
before "install_r", "EC2:start"


desc "run QC checks on the raw data"
task :qc_expression_data, :roles => group_name do
#  run 'wget "http://github.com/cassj/manu_rest_project/raw/master/illumina_qc.R" -O /mnt/scripts/.R'
#  run 'wget "http://github.com/cassj/manu_rest_project/raw/master/limma_xpn.R" -O /mnt/scripts/limma_xpn.R'
#  run 'Rscript /mnt/scripts/limma_xpn.R'
end
before "qc_expression_data", "EC2:start"


desc "run pre-processing on expression data"
task :pp_expression_data, :roles => group_name do
  run "mkdir -p #{working_dir}/scripts"
  upload("scripts/limma_xpn.R",  "#{working_dir}/scripts/limma_xpn.R")
  run "chmod +x #{working_dir}/scripts/limma_xpn.R"
  datafile = "#{mount_point}/Pas_aSVZ_DN-REST_illumina_sept10_Sample_Probe_Profile.txt"
  puts "cd #{mount_point} && Rscript #{working_dir}/scripts/limma_xpn.R #{mount_point}/limma_results.csv"
end
before "pp_expression_data", "EC2:start"


desc "run QC checks on the pre-processed quality control"
task "pp_qc_expression_data", :foles => group_name do
  #do some stuff
end  


desc "Fetch ReMoat data which has mm9 probe positions"
task :get_remoat_anno, :roles => group_name do
  run "mkdir -p #{working_dir}/lib"
  run "rm -Rf  #{working_dir}/lib/Annotation_Illumina_Mouse*"
  run "cd #{working_dir}/lib && curl http://www.compbio.group.cam.ac.uk/Resources/Annotation/final/Annotation_Illumina_Mouse-WG-V1_mm9_V1.0.0_Aug09.zip > Annotation_Illumina_Mouse-WG-V1_mm9_V1.0.0_Aug09.zip "
  run "cd #{working_dir}/lib && unzip Annotation_Illumina_Mouse-WG-V1_mm9_V1.0.0_Aug09.zip"
end 
before 'get_remoat_anno', 'EC2:start'


desc "Make an IRanges RangedData object from expression data"
task :xpn2rd, :roles => group_name do
  user = variables[:ssh_options][:user]
  run "cd #{working_dir}/scripts && curl 'http://github.com/cassj/DNREST_expression_mouse_astrocyte_volta/raw/master/scripts/xpn_csv_to_iranges.R' >  xpn_csv_to_iranges.R"
  run "cd #{working_dir}/scripts && chmod +x xpn_csv_to_iranges.R"
  run "cd #{mount_point} && Rscript #{working_dir}/scripts/xpn_csv_to_iranges.R limma_results.csv #{working_dir}/lib/Annotation_Illumina_Mouse-WG-V1_mm9_V1.0.0_Aug09.txt"
end
before "xpn2rd","EC2:start"  

desc "Fetch dataset in csv format"
task :get_limma_results, :roles=> group_name do
  `mkdir -p results`
  download("#{mount_point}/limma_rd.csv", "results/limma_rd.csv")
end 
before "get_limma_results", "EC2:start"

#cap EBS:snapshot
#cap EBS:unmount
#cap EBS:delete
#cap EC2:stop

