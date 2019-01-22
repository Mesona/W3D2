require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
  include Singleton
  
  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :id, :fname, :lname

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.find_by_id(id)
    user = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL

    # test.each { |datum| User.new(datum) }

    User.new(user[0])
  end

  def self.find_by_name(fname, lname)

    user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL

    User.new(user[0])
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end
  
  def authored_replies
    Reply.find_by_author_id(self.id)
  end
end

class Question
  attr_accessor :id, :title, :body, :author_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.find_by_id(id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL

    Question.new(question[0])
  end

  def self.find_by_author_id(author_id)
    return "No Questions" if author_id == nil
    question = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = ?
    SQL

    Question.new(question[0])
  end

  def author
    author = QuestionsDBConnection.instance.execute(<<-SQL, self.author_id)
    SELECT
      fname, lname
    FROM
      users
    WHERE
      users.id = ?
    SQL

    author[0]
  end

  def replies
    replies = Reply.find_by_question_id(self.id)
    return "Replies Empty" if replies.empty?
    replies
  end


end

# class QuestionFollows

#   attr_accessor :follower_id, :question_id

#   def initialize(options)
#     @follower_id = options['follower_id']
#     @question_id = options['question_id']
#   end

# end


class Reply

  attr_accessor :id, :original_post, :parent_reply, :body, :author_id

  def initialize(options)
    @id = options['id']
    @original_post = options['original_post']
    @parent_reply = options['parent_reply']
    @body = options['body']
    @author_id = options['author_id'] 
  end

  def self.find_by_id(id)
    reply = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL

    Reply.new(reply[0])
  end

  def self.find_by_question_id(question_id)
    return "No Replies" if question_id.nil?
    replies = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        original_post = ?
    SQL

    # Reply.new(replies[0])
    replies.map { |datum| Reply.new(datum) }
  end

  def self.find_by_author_id(author_id)
    return "No Replies" if author_id == nil
    replies = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      replies
    WHERE
      author_id = ?
    SQL

    replies.map { |datum| Reply.new(datum) }
  end


  def author
    author = QuestionsDBConnection.instance.execute(<<-SQL, self.author_id)
    SELECT
      fname, lname
    FROM
      users
    WHERE
      users.id = ?
    SQL

    author[0]
  end

  def question
    question = QuestionsDBConnection.instance.execute(<<-SQL, self.original_post)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.id = ?
    SQL

    question[0]
  end

  def topmost_reply
    return "Topmost Reply" if self.parent_reply == nil
    parent_reply = QuestionsDBConnection.instance.execute(<<-SQL, self.parent_reply)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.id = ?
    SQL

    parent_reply[0]
  end
end


