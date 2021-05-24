class LogParser

  def print_game_log(file_path_string)
    file_path = File.join(File.dirname(__FILE__), file_path_string)
    result = parse_file file_path

    result.each do |key, data|
      p '--------------------------------------------------------'
      p data
      p "> Game: #{key.to_s}"
      p "- Total Kills: #{data[:total_kills]}"
      p "- Players:"
      data[:players].each do |player|
        p "  - #{player}"
      end

      p '- Killers Ranking:'
      data[:kills].each do |killer, quantity|
        p "  - #{killer}: #{quantity}"
      end

      p '- Kills by means:'
      data[:kills_by_means].each do |mean, quantity|
        p "  - #{mean}: #{quantity}"
      end
    end
  end

  def parse_file(file_path)
    file = open_file(file_path)
    result = process_file(file)

    result
  end

  def open_file(file_path)
    File.open(file_path, 'r+')
  end

  def process_file(file)
    result = {}
    index = 0

    file.each do |line|
      if line.include? 'InitGame'
        index += 1
        kills = 0
        result = create_base_structure result, index
      end

      result = process_players line, result, index
      
      result = process_kills line, result, index
    end

    result
  end

  def create_base_structure(data, index)
    data.merge( "game_#{index}": {
      "total_kills": 0,
      "players": [],
      "kills": {},
      "kills_by_means": {}
    } )
  end

  def process_players(line, result, index)
    return result unless line.include? 'ClientUserinfoChanged:'
    
    player_name = line[/#{Regexp.escape("n\\")}(.*?)#{Regexp.escape("\\t")}/m, 1]
    
    result["game_#{index}".to_sym][:players].push player_name unless result["game_#{index}".to_sym][:players].include? player_name

    return result
  end

  def process_kills(line, result, index)
    return result unless line.include? 'Kill:'
    
    result["game_#{index}".to_sym][:total_kills] += 1

    killer_player = line[/#{"Kill: \\d{1,4} \\d{1,3} \\d{1,3}: "}(.*?)#{" killed "}/m, 1]

    if killer_player.eql? '<world>'
      killed_player = line[/#{" killed "}(.*?)#{" by "}/m, 1]
      result = sum_kills result, killed_player, index, -1
      return result 
    end

    result = sum_kills result, killer_player, index, 1

    result["game_#{index}".to_sym][:kills_by_means] = process_kill_mean result["game_#{index}".to_sym][:kills_by_means], line

    return result
  end

  def sum_kills(result, player, index, value)
    if result["game_#{index}".to_sym][:kills][player].nil? 
      result["game_#{index}".to_sym][:kills][player] = value
    else
      result["game_#{index}".to_sym][:kills][player] += value
    end

    result["game_#{index}".to_sym][:kills] = sort_hash(result["game_#{index}".to_sym][:kills])

    return result
  end

  def sort_hash(hash)
    result = hash.sort_by { |k, v| v }.reverse.to_h
    return result
  end

  def process_kill_mean(kills_means_hash, line)
    kill_mean = line[/#{" by "}(.*?)#{Regexp.escape("\n")}/m, 1]

    kills_means_hash = {} if kills_means_hash.nil?

    if kills_means_hash[kill_mean.to_sym].nil?
      kills_means_hash[kill_mean.to_sym] = 1
    else
      kills_means_hash[kill_mean.to_sym] += 1
    end

    kills_means_hash = sort_hash(kills_means_hash)

    return kills_means_hash
  end

end