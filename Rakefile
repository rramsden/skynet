desc "Deploy website"
task :deploy do
  system("rsync -avvz --rsh='ssh -p1337' --delete $(pwd)/ deploy@gamenao.com:~/skynet")
end
