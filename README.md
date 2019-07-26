# Getting VCF-Server started with [Docker](https://www.docker.com/)
<p>Type this into your commandline</p>

`docker run -d -p 8000:9000 jiangjp880123/vcf-server`   

<p>Then visit http://localhost:8000</p>
<p>Default admin account: admin/admin</p>
<p>Default public account: public/public</p>

<p>Relevant links:</p>

[VCF-Server Homepage](http://diseasegps.sjtu.edu.cn/VCF-Server?lan=eng)


# More advanced usage

<p>Store data on local:</p>

`mkdir data`   
`docker run -d -p 8000:9000 -v ${PWD}/data:data jiangjp880123/vcf-server`   

<p>Build from Dockerfile: </p>

`docker build -t vcfserver .`
