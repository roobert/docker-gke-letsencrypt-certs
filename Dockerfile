FROM google/cloud-sdk

ADD /gke-letsencrypt-certs.rb /gke-letsencrypt-certs.rb

CMD [ "/gke-letsencrypt-certs.rb" ]
