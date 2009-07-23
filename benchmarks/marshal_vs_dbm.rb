require 'benchmark'
require 'dbm'

MARSHAL_FILE = "marshal_test.db"
DBM_FILE = "dbm_test"
WRITE_TIMES = 50
READ_TIMES = 100
INDICES = ['33', '857', '5022', '98555']

def access_indices(db)
  INDICES.each {|index| db[index] }
end

def setup_dbs(handle, file)
  File.unlink(file + (file == DBM_FILE ? ".db" : '')) if File.exist?(file)
  handles = [{}, ]
  handles.each do |handle|
    10000.times {|t| handle[t.to_s] = '0' * (rand * 1024).floor }
    if handle.is_a?(Hash)
      File.open(MARSHAL_FILE, "w") {|f| f.write(Marshal.dump(handle)) }
    else
      handle.close
    end
  end
end

Benchmark.bmbm do |x|
  x.report("marshal-write") { WRITE_TIMES.times { setup_dbs({}, MARSHAL_FILE) } }
  x.report("dbm-write") { WRITE_TIMES.times { setup_dbs(DBM.new(DBM_FILE), DBM_FILE) } }
  x.report("marshal-read ") { READ_TIMES.times { access_indices(Marshal.load(File.read(MARSHAL_FILE))) } }
  x.report("dbm-read ") { READ_TIMES.times { DBM.open(DBM_FILE) {|db| access_indices(db) } } }
end

File.unlink(MARSHAL_FILE)
File.unlink(DBM_FILE + ".db")

__END__

Rehearsal -------------------------------------------------
marshal-write   3.020000   0.830000   3.850000 (  7.166425)
dbm-write       3.030000   0.790000   3.820000 (  5.569607)
marshal-read    3.680000   0.860000   4.540000 (  4.592529)
dbm-read        0.010000   0.020000   0.030000 (  0.056891)
--------------------------------------- total: 12.240000sec

                    user     system      total        real
marshal-write   3.020000   0.800000   3.820000 (  7.067850)
dbm-write       2.960000   0.780000   3.740000 (  5.761866)
marshal-read    3.490000   0.850000   4.340000 (  4.386992)
dbm-read        0.010000   0.020000   0.030000 (  0.059572)
