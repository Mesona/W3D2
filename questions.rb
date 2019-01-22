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
  attr_accessor :id, :fname, :lname, :is_instructor

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
    @is_instructor = options['is_instructor']
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

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end

  def average_karma
    questions_and_likes = QuestionsDBConnection.instance.execute(<<-SQL, self.id)
    SELECT
      (CAST(COUNT(question_likes.user_id) AS FLOAT) / COUNT(DISTINCT(questions.id))) 
    FROM
      questions
    LEFT JOIN question_likes
    ON questions.id = question_likes.question_id
    WHERE
      questions.author_id = ?
    SQL

    questions_and_likes[0].values[0]
  end

  def save
    if self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.fname, self.lname, self.is_instructor, self.id)
        UPDATE
          users
        SET
          fname = ?, lname = ?, is_instructor = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, self.fname, self.lname, self.is_instructor)
        INSERT INTO
          users (fname, lname, is_instructor)
        VALUES
          (?, ?, ?)
      SQL
      self.id = QuestionsDBConnection.instance.last_insert_row_id
    end
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

  def followers
    QuestionFollow.followers_for_question_id(self.id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def save
    if self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.title, self.body, self.author_id, self.id)
        UPDATE
          questions
        SET
          title = ?, body = ?, author_id = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, self.title, self.body, self.author_id)
        INSERT INTO
          questions (title, body, author_id)
        VALUES
          (?, ?, ?)
      SQL
      self.id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end
end

class QuestionFollow

  attr_accessor :follower_id, :question_id

  def initialize(options)
    @follower_id = options['follower_id']
    @question_id = options['question_id']
  end

  def self.followers_for_question_id(question_id)

    followers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      users
    JOIN question_follows
    ON question_follows.follower_id = users.id
    WHERE
      question_follows.question_id = ?
    SQL

    followers.map {|datum| User.new(datum)}
  end

  def self.followed_questions_for_user_id(user_id)
    followed = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      questions
    JOIN question_follows
    ON question_follows.question_id = questions.id
    WHERE
      question_follows.follower_id = ?
    SQL

    followed.map {|datum| Question.new(datum)}
  end

  def self.most_followed_questions(n)
    most_followed = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM
        questions
      JOIN question_follows
      ON question_follows.question_id = questions.id
      GROUP BY question_follows.question_id
      ORDER BY COUNT(question_follows.follower_id) DESC
      LIMIT ?
    SQL

    most_followed.map { |datum| Question.new(datum)}
  end

end


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

  def child_replies
    child_replies = QuestionsDBConnection.instance.execute(<<-SQL, self.id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_reply = ?
    SQL

    child_replies.map {|datum| Reply.new(datum)}
  end

  def save
    if self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.original_post, self.parent_reply, self.body, self.author_id, self.id)
        UPDATE
          replies
        SET
          original_post = ?, parent_reply = ?, body = ?, author_id = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, self.original_post, self.parent_reply, self.body, self.author_id)
        INSERT INTO
          replies (original_post, parent_reply, body, author_id)
        VALUES
          (?, ?, ?, ?)
      SQL
      self.id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end
  
end

class QuestionLike
  attr_accessor :user_id, :question_id

  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.likers_for_question_id(question_id)
    likers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      users
    JOIN
      question_likes ON question_likes.user_id = users.id
    WHERE
      question_likes.question_id = ?
    SQL

    likers.map {|datum| User.new(datum)}
  end

  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(*)
    FROM
      users
    JOIN
      question_likes ON question_likes.user_id = users.id
    WHERE
      question_likes.question_id = ?
    SQL

    num_likes[0].values[0]
  end

  def self.liked_questions_for_user_id(user_id)
    liked_questions = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      questions
    JOIN
      question_likes ON question_likes.question_id = questions.id
    WHERE
      question_likes.user_id = ?
    SQL

    liked_questions.map {|datum| Question.new(datum)}
  end

  def self.most_liked_questions(n)
    most_liked = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM
        questions
      JOIN question_likes
      ON question_likes.question_id = questions.id
      GROUP BY question_likes.question_id
      ORDER BY COUNT(question_likes.user_id) DESC
      LIMIT ?
    SQL

    most_liked.map {|datum| Question.new(datum)}
  end

end