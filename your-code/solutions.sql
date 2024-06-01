use publications_db

/*Challenge 1 - Most Profiting Authors*/
/*royalties of each sale for each author*/
SELECT
    sales.title_id,
    titleauthor.au_id,
    (titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100) AS sales_royalty
FROM
    sales
JOIN
    titles ON sales.title_id = titles.title_id
JOIN
    titleauthor ON titles.title_id = titleauthor.title_id;


SELECT * FROM authors;
SELECT * FROM sales;
SELECT * FROM titles
SELECT * FROM titleauthor

/*the total royalties for each title for each author*/
SELECT
    title_id,
    au_id,
    SUM(sales_royalty) AS total_royalties
FROM
    (
        SELECT
            sales.title_id,
            titleauthor.au_id,
            (titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100) AS sales_royalty
        FROM
            sales
        JOIN
            titles ON sales.title_id = titles.title_id
        JOIN
            titleauthor ON titles.title_id = titleauthor.title_id
    ) AS sales_royalties
GROUP BY
    title_id,
    au_id;
    
    /*profits of each author*/
    SELECT
    authors.au_id AS "AUTHOR ID",
    authors.au_lname AS "LAST NAME",
    authors.au_fname AS "FIRST NAME",
    SUM(titles.advance) + SUM(total_royalties) AS total_profits
FROM
    (
        SELECT
            title_id,
            au_id,
            SUM(sales_royalty) AS total_royalties
        FROM
            (
                SELECT
                    sales.title_id,
                    titleauthor.au_id,
                    (titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100) AS sales_royalty
                FROM
                    sales
                JOIN
                    titles ON sales.title_id = titles.title_id
                JOIN
                    titleauthor ON titles.title_id = titleauthor.title_id
            ) AS sales_royalties
        GROUP BY
            title_id,
            au_id
    ) AS royalties
JOIN
    titles ON royalties.title_id = titles.title_id
JOIN
    authors ON royalties.au_id = authors.au_id
GROUP BY
    authors.au_id, authors.au_lname, authors.au_fname
ORDER BY
    total_profits DESC
LIMIT 3;

/*Challenge 2 - Alternative Solution*/
/* royalties of each sale for each author*/

-- Drop the temporary table if it already exists
DROP TEMPORARY TABLE IF EXISTS temp_sales_royalties;

-- Create the temporary table for sales royalties
CREATE TEMPORARY TABLE temp_sales_royalties AS
SELECT
    sales.title_id,
    titleauthor.au_id,
    (titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100) AS sales_royalty
FROM
    sales
JOIN
    titles ON sales.title_id = titles.title_id
JOIN
    titleauthor ON titles.title_id = titleauthor.title_id;

/*total royalties for each title for each author*/
-- Drop the temporary table if it already exists
DROP TEMPORARY TABLE IF EXISTS temp_total_royalties;

-- Create the temporary table for total royalties
CREATE TEMPORARY TABLE temp_total_royalties AS
SELECT
    title_id,
    au_id,
    SUM(sales_royalty) AS total_royalties
FROM
    temp_sales_royalties
GROUP BY
    title_id,
    au_id;

/* total profits of each author*/
-- Drop the temporary table if it already exists
DROP TEMPORARY TABLE IF EXISTS temp_author_profits;

-- Create the temporary table for author profits
CREATE TEMPORARY TABLE temp_author_profits AS
SELECT
    authors.au_id AS "AUTHOR ID",
    authors.au_lname AS "LAST NAME",
    authors.au_fname AS "FIRST NAME",
    SUM(titles.advance) + SUM(temp_total_royalties.total_royalties) AS total_profits
FROM
    temp_total_royalties
JOIN
    titles ON temp_total_royalties.title_id = titles.title_id
JOIN
    authors ON temp_total_royalties.au_id = authors.au_id
GROUP BY
    authors.au_id, authors.au_lname, authors.au_fname
ORDER BY
    total_profits DESC
LIMIT 3;

--  the final result from the temporary table
SELECT *
FROM temp_author_profits;


/*Challenge 3*/
/*Create the most_profiting_authors Table*/

-- Drop the table if it already exists
DROP TABLE IF EXISTS most_profiting_authors;

-- Create the permanent table
CREATE TABLE most_profiting_authors (
    au_id INT PRIMARY KEY,
    profits DECIMAL(15, 2)
);

-- Insert Data 
-- Step 1: Calculate the royalties of each sale for each author
CREATE TEMPORARY TABLE temp_sales_royalties AS
SELECT
    sales.title_id,
    titleauthor.au_id,
    (titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100) AS sales_royalty
FROM
    sales
JOIN
    titles ON sales.title_id = titles.title_id
JOIN
    titleauthor ON titles.title_id = titleauthor.title_id;

-- Step 2: the total royalties for each title for each author
CREATE TEMPORARY TABLE temp_total_royalties AS
SELECT
    title_id,
    au_id,
    SUM(sales_royalty) AS total_royalties
FROM
    temp_sales_royalties
GROUP BY
    title_id,
    au_id;

-- Step 3: Calculate the total profits of each author and insert into most_profiting_authors
INSERT INTO most_profiting_authors (au_id, profits)
SELECT
    authors.au_id,
    SUM(titles.advance) + SUM(temp_total_royalties.total_royalties) AS total_profits
FROM
    temp_total_royalties
JOIN
    titles ON temp_total_royalties.title_id = titles.title_id
JOIN
    authors ON temp_total_royalties.au_id = authors.au_id
GROUP BY
    authors.au_id
ORDER BY
    total_profits DESC;

-- Clean up temporary tables
DROP TEMPORARY TABLE IF EXISTS temp_sales_royalties;
DROP TEMPORARY TABLE IF EXISTS temp_total_royalties;

