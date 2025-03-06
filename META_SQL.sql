
-- User Summary View

CREATE VIEW user_summary AS
    SELECT 
        a.id AS UserID,
        a.username AS Username,
        COALESCE(COUNT(b.id), 0) AS Total_Photos,
        COALESCE(SUM(Likes), 0) AS Total_Likes,
        COALESCE(SUM(Comments), 0) AS Total_Comments,
        COALESCE(SUM(Tags), 0) AS Total_Tags,
        COALESCE(Posts_Liked, 0) AS Posts_Liked,
        COALESCE(Comments_Made, 0) AS Comments_Made,
        COALESCE(Total_followers, 0) AS Total_followers,
        COALESCE(Total_followings, 0) AS Total_followings
    FROM
        users a
            LEFT JOIN
        photos b ON a.id = b.user_id
            LEFT JOIN
        (SELECT 
            photo_id, COUNT(*) AS Likes
        FROM
            likes
        GROUP BY photo_id) c ON b.id = c.photo_id
            LEFT JOIN
        (SELECT 
            photo_id, COUNT(*) AS Comments
        FROM
            comments
        GROUP BY photo_id) d ON b.id = d.photo_id
            LEFT JOIN
        (SELECT 
            photo_id, COUNT(*) AS Tags
        FROM
            photo_tags
        GROUP BY photo_id) e ON b.id = e.photo_id
            LEFT JOIN
        (SELECT 
            user_id, COUNT(id) AS Comments_Made
        FROM
            comments
        GROUP BY user_id) f ON a.id = f.user_id
            LEFT JOIN
        (SELECT 
            user_id, COUNT(photo_id) AS Posts_Liked
        FROM
            likes
        GROUP BY user_id) g ON a.id = g.user_id
            LEFT JOIN
        (SELECT 
            followee_id AS id, COUNT(follower_id) AS Total_followers
        FROM
            follows
        GROUP BY followee_id) h ON a.id = h.id
            LEFT JOIN
        (SELECT 
            follower_id AS id, COUNT(followee_id) AS Total_followings
        FROM
            follows
        GROUP BY follower_id) i ON a.id = i.id
    GROUP BY a.id , a.username;

-- Photo Summary View

create view  photo_summary as
select user_id as UserID, id as PhotoID, Likes, Comments, Tags from photos b
left join 
(select photo_id, count(*) as Likes from likes group by photo_id) c
on b.id=c.photo_id
left join 
(select photo_id, count(*) as Comments from comments group by photo_id) d
on b.id=d.photo_id
left join 
(select photo_id, count(*) as Tags from photo_tags group by photo_id) e
on b.id=e.photo_id;

-- Objective Question- 2. What is the distribution of user activity levels
-- (e.g., number of posts, likes, comments) across the user base?


SELECT 
    COUNT(a.id) AS Total_Photos,
    SUM(Likes) AS Total_Likes,
    SUM(Comments) AS Total_Comments
FROM
    photos a
        LEFT JOIN
    (SELECT 
        photo_id, COUNT(*) AS Likes
    FROM
        likes
    GROUP BY photo_id) b ON a.id = b.photo_id
        LEFT JOIN
    (SELECT 
        photo_id, COUNT(*) AS Comments
    FROM
        comments
    GROUP BY photo_id) c ON a.id = c.photo_id;

--  Objective Question- 3. Calculate the average number of tags per post
-- (photo_tags and photos tables).

SELECT 
    ROUND(AVG(COALESCE(tags, 0)), 2) AS Avg_Tags_Per_Post
FROM
    photos a
        LEFT JOIN
    (SELECT 
        photo_id, COUNT(tag_id) AS tags
    FROM
        photo_tags
    GROUP BY photo_id) b ON a.id = b.photo_id;

-- Objective Question- 4. Identify the top users with the highest 
-- engagement rates (likes, comments) on their posts and rank them.


SELECT 
    UserID,
    username,
    Total_likes,
    Total_Comments,
    (Total_likes + Total_Comments) AS Total_Engagement,
	RANK() OVER(ORDER BY (Total_likes + Total_Comments) DESC) AS Top_Ranked_Users
FROM
    user_summary;


-- Objective Question- 5. Which users have the highest number of followers and followings?

SELECT 
    UserID, username, Total_Followers, Total_Followings
FROM
    user_summary
ORDER BY (Total_Followers + Total_Followings) DESC;

-- other

select a.id as user_id, username, Total_Followers, Total_Followings from users a
left join
(select followee_id as id, count(follower_id) as Total_followers
from follows
group by followee_id)b
on a.id=b.id
left join 
(select follower_id as id, count(followee_id) as Total_followings
from follows
group by follower_id)c 
on a.id=c.id
order by Total_Followers, Total_Followings;


-- Objective Question- 6. Calculate the average engagement rate (likes, comments)
-- per post for each user.

SELECT 
    UserID,
    username,
    Total_Photos,
    Total_Likes,
    Total_Comments,
    ROUND((Total_Likes + Total_Comments) / Total_Photos,2) AS Average_Engagement_Rate,
    RANK() OVER( ORDER BY (Total_Likes+Total_Comments)/Total_Photos DESC) AS Top_Users_Rank
FROM
    user_summary;

-- Objective Question- 7. Get the list of users who have never
-- liked any post (users and likes tables)

SELECT 
    id AS UserID, username AS Users_Never_Liked_Any_Post
FROM
    users
WHERE
    id NOT IN (SELECT DISTINCT
            user_id
        FROM
            likes);
 
 -- Objective Question- 8. How can you leverage user-generated 
 -- content (posts, hashtags, photo tags) to create more 
 -- personalized and engaging ad campaigns?

WITH tags_avg_likes AS (SELECT 
    a.tag_id, ROUND(AVG(Total_likes),2) AS Avg_Likes, count(a.photo_id) as Times_Tag_Used
FROM
    photo_tags AS a
        INNER JOIN
    (SELECT 
        photo_id, COUNT(user_id) AS Total_likes
    FROM
        likes
    GROUP BY photo_id) b ON a.photo_id = b.photo_id
GROUP BY tag_id
)

SELECT 
    id AS tag_id, tag_name, Avg_Likes, Times_Tag_Used
FROM
    tags a
        LEFT JOIN
    tags_avg_likes b ON id = tag_id
ORDER BY Avg_Likes DESC;
 
-- Objective Question Question- 10. Calculate the total number of likes,
-- comments, and photo tags for each user.

SELECT 
    UserID,
    username,
    Total_Photos,
    Total_Likes,
    Total_Comments,
    Total_Tags
FROM
    user_summary; 
    
-- Objective Question- 11. Rank users based on their total engagement (likes,
-- comments, shares) over a month.

with Posts_Liked as (select user_id, count(*) as Engagement , DATE_FORMAT(created_at,'%y-%c') as MY from likes
group by user_id, MY ),

Comments_Made as (select user_id, count(*) as Engagement , DATE_FORMAT(created_at,'%y-%c') as MY from comments
group by user_id, MY ),

Total_Likes as (select b.user_id, count(*) as Engagement,  DATE_FORMAT(created_at,'%y-%c') as MY from likes a 
left join photos b 
on a.photo_id=b.id
group by b.user_id, MY ),

Total_Comments as (select b.user_id, count(*) as Engagement,  DATE_FORMAT(created_at,'%y-%c') as MY from comments a 
left join photos b 
on a.photo_id=b.id
group by b.user_id, MY ),

Total_Engagement as (select * from Posts_Liked
union all
select * from Comments_Made
union all
select * from Total_Likes
union all
select * from Total_Comments)

select MY, username, sum(Engagement) as Total_Engagement,
rank() over(partition by MY order by sum(Engagement) desc) as Monthly_Top_Users
from Total_Engagement a
left join users b
on a.user_id=b.id
group by MY, user_id;
    
-- Objective Question- 12. Retrieve the hashtags that have been used in posts with the
-- highest average number of likes. Use a CTE to calculate the average likes
-- for each hashtag first.

WITH tags_avg_likes AS (SELECT 
    a.tag_id, ROUND(AVG(Total_likes),2) AS Avg_Likes, count(a.photo_id) as Times_Tag_Used
FROM
    photo_tags AS a
        INNER JOIN
    (SELECT 
        photo_id, COUNT(user_id) AS Total_likes
    FROM
        likes
    GROUP BY photo_id) b ON a.photo_id = b.photo_id
GROUP BY tag_id
)

SELECT 
    id AS tag_id, tag_name, Avg_Likes, Times_Tag_Used
FROM
    tags a
        LEFT JOIN
    tags_avg_likes b ON id = tag_id
ORDER BY Avg_Likes DESC;

-- Objective Question- 13. Retrieve the users who have started following someone after
-- being followed by that person

SELECT 
    a.followee_id AS user_id
FROM
    follows a
        INNER JOIN
    follows b ON a.followee_id = b.follower_id
        AND b.followee_id = a.follower_id
        AND a.created_at < b.created_at;
        
        
-- Subjective Question- 1. Based on user engagement and activity levels, which users would
--  you consider the most loyal or valuable? How would you reward or incentivize these users?    

SELECT 
    *,
    (Total_Likes + Total_Comments + Total_Tags + Posts_Liked + Comments_Made + Total_followers + Total_followings) AS Total_Engagement
FROM
    user_summary
WHERE
    Total_Photos > (SELECT 
            AVG(Total_Photos)
        FROM
            user_summary)
        AND Total_Likes > (SELECT 
            AVG(Total_Likes)
        FROM
            user_summary)
        AND Total_Comments > (SELECT 
            AVG(Total_Comments)
        FROM
            user_summary)
ORDER BY Total_Engagement DESC
LIMIT 20;

-- Subjective Question- 2. For inactive users, what strategies would you recommend to re-engage
-- them and encourage them to start posting or engaging again?

SELECT 
    *,
    (Total_Likes + Total_Comments + Total_Tags + Posts_Liked + Comments_Made + Total_followers + Total_followings) AS Total_Engagement
FROM
    user_summary
ORDER BY Total_Engagement
LIMIT 20;

-- Subjective Question- 3. Which hashtags or content topics have the highest engagement rates?
-- How can this information guide content strategy and ad campaigns?

WITH tags_engagement AS (SELECT 
    a.tag_id,
    SUM(Total_Likes) AS Total_Likes,
    SUM(Total_Comments) AS Total_Comments,
    ROUND(AVG(Total_Likes), 2) AS Avg_Likes,
    ROUND(AVG(Total_Comments), 2) AS Avg_Comments,
    COUNT(a.photo_id) AS Times_Tag_Used
FROM
    photo_tags AS a
        INNER JOIN
    (SELECT 
        photo_id, COUNT(user_id) AS Total_Likes
    FROM
        likes
    GROUP BY photo_id) b ON a.photo_id = b.photo_id
    
    INNER JOIN
    (SELECT 
        photo_id, COUNT(user_id) AS Total_Comments
    FROM
        comments
    GROUP BY photo_id) c ON a.photo_id = c.photo_id
    
GROUP BY tag_id
)

SELECT 
    id AS tag_id,
    tag_name,
    Total_Likes,
    Total_Comments,
    Avg_Likes,
    Avg_Comments,
    (Total_Likes + Total_Comments) AS Total_Engagement,
    (Avg_Likes + Avg_Comments) AS Avg_Engagement,
    Times_Tag_Used
FROM
    tags a
        LEFT JOIN
    tags_engagement b ON id = tag_id
WHERE
    (Total_Likes + Total_Comments) > (SELECT 
            AVG(Total_Likes + Total_Comments)
        FROM
            tags_engagement)
ORDER BY Avg_Engagement DESC;

-- Subjective Question- 4. Are there any patterns or trends in user engagement based on demographics
-- (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?

with cte as (select * from likes
union all
select user_id, photo_id, created_at from comments)

select dayname(created_at) as Day, count(*) as total_activity from cte
group by dayname(created_at)
order by Day desc;

select hour(created_at) HH, count(*) as total_activity from cte
group by hour(created_at)
Order by HH Desc;

-- Subjective Question- 5. Based on follower counts and engagement rates, which users would be ideal 
-- candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?

SELECT 
    UserID,
    Username,
    (Total_Likes + Total_Comments) AS Total_Engagement,
    Total_Followers
FROM
    user_summary
ORDER BY Total_Engagement DESC , Total_Followers DESC
LIMIT 10;

-- Subjective Question- 6. Based on user behavior and engagement data, how would you segment the user base for 
-- targeted marketing campaigns or personalized recommendations?

with user_segment as  (select * , (Total_Likes + Total_Comments + Posts_Liked + Comments_Made + Total_Followers + Total_Followings) as Total_Engagement,
case 
when Total_Photos = 0 and Posts_Liked = 0 and Comments_Made= 0 then "4"
when Total_Photos = 0 then "3"
when Total_Photos <= (SELECT AVG(Total_Photos) from user_summary)
and Total_Likes <= (SELECT AVG(Total_Likes) from user_summary)
AND Total_Comments <= (SELECT AVG(Total_Comments) from user_summary) then "2" else "1"
end as Segment from user_summary)

select Total_Photos, Total_Likes, Total_Comments, Posts_Liked, Comments_Made, Total_Followers, Total_Followings, Total_Engagement,
case when Segment = 1 then "Active User"
when Segment = 2 then "Moderate User"
when Segment = 3 then "Passive User"
when Segment = 4 then "Inactive User" end as "User_Category" 
from user_segment
order by segment, Total_Engagement desc;

select count(*) User_Count,
case when Segment = 1 then "Active User"
when Segment = 2 then "Moderate User"
when Segment = 3 then "Passive User"
when Segment = 4 then "Inactive User" end as "User_Category" 
from user_segment
group by segment
order by User_Count desc;

-- Inactive Users

select * from user_summary where Total_Photos = 0 and Posts_Liked=0 and Comments_Made=0;

-- Passive Users

select * from user_summary where Total_Photos = 0 and (Posts_Liked>0 or Comments_Made>0);

-- Avg Summary --

select 
round(sum(Total_Likes)/sum(Total_Photos),1) as Avg_like_Per_Photo,
round(sum(Total_Comments)/sum(Total_Photos),1) as Avg_Comments_Per_Photo,
round(sum(Total_Tags)/sum(Total_Photos),1) as Avg_Tags_Per_Photo,
round(avg(Total_Photos),1) as Avg_Photo_Per_User,
round(avg(Total_Likes),1) as Avg_Like_Per_User,
round(avg(Total_Comments),1) as Avg_Comments_Per_User,
round(avg(Total_Tags),1) as Avg_Tags_Per_User,
round(avg(Total_Followers),1) as Avg_Followers_Per_User,
round(avg(Total_Followings),1) as Avg_Followings_Per_User
from user_summary;
