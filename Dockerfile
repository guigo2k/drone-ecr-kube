FROM guigo2k/aws-cli-kubectl
ADD script.sh /usr/bin/init
CMD ["/usr/bin/init"]
