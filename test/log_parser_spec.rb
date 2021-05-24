require_relative '../src/log_parser.rb'

RSpec.describe LogParser do
  before do
    @parser = LogParser.new
    @real_file = File.join(File.dirname(__FILE__), '../src/Quake.log')
  end

  context 'open_file' do
    it 'open file' do
      file = @parser.open_file(@real_file)
      expect(file).to_not be_nil
    end

    it 'should throw exception if file not existis' do
      expect{@parser.open_file('Teste.log')}.to raise_error(Errno::ENOENT)
    end

    it 'should read first line' do
      file = @parser.open_file(@real_file)
      expect(file.first).to start_with('0:00 ')
    end
  end

  context 'create basic structure' do
    let(:basic_structure) {
      {"game_1": {"total_kills": 0, "players": [], "kills": {}, "kills_by_means": {}}}
    }

    let(:basic_structure_2) {
      {"game_2": {"total_kills": 0, "players": [], "kills": {}, "kills_by_means": {}}}
    }

    it 'should return hash with basic structure' do
      result = @parser.create_base_structure({}, 1)
      expect(result).to eq(basic_structure)
    end

    it 'should return hash with basic structure with game_2' do
      result = @parser.create_base_structure({}, 2)
      expect(result).to eq(basic_structure_2)
    end
  end

  context 'parse file' do
    before do
      @basic_structure = {}
      @basic_structure = @parser.create_base_structure(@basic_structure, 1)
      @basic_structure = @parser.create_base_structure(@basic_structure, 2)

      @test_file = File.join(File.dirname(__FILE__), 'resources/test.log')
      @test_file_2 = File.join(File.dirname(__FILE__), 'resources/test2.log')
    end

    it 'should return parsed file with base structure' do
      result = @parser.parse_file @test_file
      expect(result).to eq(@basic_structure)
    end

    it 'should return structure with kill number' do
      result = @parser.parse_file @test_file_2
      expect(result[:game_1][:total_kills]).to eq(4)
    end

    it 'should return structure with all players' do
      result = @parser.parse_file @test_file_2
      expect(result[:game_1][:players].size).to eq(4)
    end

    it 'should parse real file' do
      result = @parser.parse_file @real_file
      expect(result.size).to eq(21)
    end

  end

  context 'process players' do
    it 'should return structure with player player' do
      line = '  0:27 ClientUserinfoChanged: 2 n\Mocinha\t\0\model\sarge\hmodel\sarge\g_redteam\\g_blueteam\\c1\4\c2\5\hc\95\w\0\l\0\tt\0\tl\0'
      data = {}
      data = @parser.create_base_structure(data, 1)

      result = @parser.process_players line, data, 1

      expect(result[:game_1][:players][0]).to eq('Mocinha')
    end
  end

  context 'process kills' do
    it 'should return structure with kills sumary' do
      line = "  1:08 Kill: 3 2 6: Isgalamido killed Mocinha by MOD_ROCKET\n"
      data = {}
      data = @parser.create_base_structure(data, 1)

      result = @parser.process_kills line, data, 1

      expect(result[:game_1][:kills]['Isgalamido']).to eq(1)
    end

    it 'should return structure without player <world>' do
      line = "  1:26 Kill: 1022 4 22: <world> killed Zeh by MOD_TRIGGER_HURT\n"
      data = {}
      data = @parser.create_base_structure(data, 1)

      result = @parser.process_kills line, data, 1

      expect(result[:game_1][:kills]['<world>']).to be_nil
    end

    it 'should return structure with player killed by <world> losed 1 kill score' do
      line = "  1:26 Kill: 1022 4 22: <world> killed Zeh by MOD_TRIGGER_HURT"
      data = {}
      data = @parser.create_base_structure(data, 1)
      data[:game_1][:kills]['Zeh'] = 5

      result = @parser.process_kills line, data, 1

      expect(result[:game_1][:kills]['Zeh']).to eq(4)
    end
  end

  context 'sort killers' do
    let(:data) {
      {"game_1": {"total_kills": 15, "players": [], "kills": {
        "Zeh": -1,
        "Isgalamido": 5,
        "Dono da Bola": 0,
      }}}
    }

    it 'should sort killers by num kills' do
      result = @parser.sort_hash data[:game_1][:kills]
      expect(result.keys[0].to_s).to eq('Isgalamido')
      expect(result.keys[1].to_s).to eq('Dono da Bola')
      expect(result.keys[2].to_s).to eq('Zeh')
    end
  end

  context 'kills by means' do
    it 'should return hash with kills means and numbers' do
      line = "  1:26 Kill: 1022 4 22: <world> killed Zeh by MOD_TRIGGER_HURT\n"
      hash = {}
      result = @parser.process_kill_mean hash, line

      expect(result[:MOD_TRIGGER_HURT]).to eq(1)
    end
  end

end