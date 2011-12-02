require 'sinatra'
require 'json'
require 'sqlite3'
require 'digest'
require 'snmp'

enable :sessions
manager = SNMP::Manager.new(:host => 'localhost')

ROOT_OID = "1.3.6.1.4.1.8072.9999.9999.2"
OID_LOCK = ROOT_OID + ".0"
OID_GOTO = ROOT_OID + ".2"
OID_WHERE = ROOT_OID + ".3"

get '/' do
  erb :index
end

get '/goto' do
  content_type 'application/json', :charset => 'utf-8'

  ra = params[:ra]
  dec = params[:dec]
  puts "SID: #{session[:sid].inspect}"
  status 500 and return "" unless (session[:sid] and ra and dec)

  packet = "#{session[:sid]},#{ra},#{dec}"

  varbind = SNMP::VarBind.new(OID_GOTO, SNMP::OctetString.new( packet ))
  "#{manager.set(varbind).varbind_list.first.value}"
end

get '/where' do
  content_type 'application/json', :charset => 'utf-8'

  varbind = SNMP::VarBind.new(OID_WHERE)
  "#{manager.get(varbind).varbind_list.first.value}"
end

get '/lock' do
  content_type 'application/json', :charset => 'utf-8'
  sid = Digest::SHA1.hexdigest( Time.now.to_f.to_s ).to_s

  varbind = SNMP::VarBind.new(OID_LOCK, SNMP::OctetString.new( sid ))
  resp = JSON.parse( manager.set(varbind).varbind_list.first.value )

  session[:sid] = sid if resp['sid']
  "#{resp.to_json}"
end

####
# Fetch close by stardata for a celestial object

get '/starmap/:id' do
  content_type 'application/json', :charset => 'utf-8'
  db = SQLite3::Database.new( 'stars.db' )
  res = result_to_hash( db.execute( "select * from stars where id = #{params[:id]}" ).first )

  res = db.execute <<SQL
    select * from stars where x between #{res['x'].to_i - 100} and #{res['x'].to_i + 100}
    and y between #{res['y'].to_i - 100} and #{res['y'].to_i + 100}
    and (name is not null or bayer is not null)
SQL

  res.inject({}) do |accum,entry|
    accum[entry[0]] = result_to_hash(entry)
    accum
  end.to_json
end

def result_to_hash(res)
  h = {}
  ['id','name','bayer','ra','dec','distance','absmag','mag','color','x','y','z'].each_with_index do |col,i|
    res = (res == "null" ? nil : res)
    h[col] = res[i]
  end
  return h
end
