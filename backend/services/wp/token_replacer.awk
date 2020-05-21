BEGIN{
    FS=","
    counter=0
  }

{
    if($0 ~ /define\(.*'put your unique phrase here'\s+\);/){

        printf "\n%s,'token_%d');",  $1 ,counter
    counter+=1

    }else{
        print $0
    }
    
    }