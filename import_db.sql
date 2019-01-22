PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;


CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL,
  is_instructor VARCHAR(5) NOT NULL
);


CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  
  FOREIGN KEY (author_id) REFERENCES users(id)
  );

CREATE TABLE question_follows (
  follower_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (follower_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  original_post INTEGER NOT NULL,
  parent_reply INTEGER,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (original_post) REFERENCES questions(id),
  FOREIGN KEY (parent_reply) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname, is_instructor)
VALUES
  ('Joe', 'Bob', 'true'),
  ('Steve', 'Bill', 'false');


INSERT INTO
  questions (title, body, author_id)
VALUES
  ('Q1', 'body body body?', 1),
  ('Q2', 'more body body body?', 2),
  ('Q3', 'les body?', 2);

INSERT INTO
  replies (original_post, parent_reply, body, author_id)
VALUES
  (1, NULL, 'filler for this', 2),
  (1, 1, 'this is a sub reply', 1),
  (2, NULL, 'question 2 reponse', 1),
  (1, NULL, 'Filler MK 2, the fillering', 2);