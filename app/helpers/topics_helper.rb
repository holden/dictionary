module TopicsHelper
  def abbreviate_part_of_speech(part)
    case part.to_s
    when 'noun' then 'n'
    when 'verb' then 'v'
    when 'adjective' then 'adj'
    when 'adverb' then 'adv'
    else 'n'  # default to noun if unknown
    end
  end
end 