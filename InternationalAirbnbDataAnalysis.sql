/*
Ramy Batta SQL Portfolio Project:

International Airbnb Data Analysis

This project is centered around analyzing a public Airbnb dataset that contains information about different
listings' information, host, and reviews from Airbnbs in ten cities that attract tourists internationally.

The data is contained in the schema ProjectAirbnb that contains the following tables:
- host_information
- listing_reviews
- property_details
- exchange_rates

The project aims to develop and practice my proficiency in data aggregation and insights generation. It 
delves into various aspects of the Airbnb industry that I find interesting as a user of the service and
seeks potential benefits of hosting properties. The analysis attempts to identify optimal options for 
property rental while providing valuable insights for potential hosts and stakeholders. Through a number of
structured SQL queries and analysis of their result sets, this project highlights key trends and patterns
within the Airbnb ecosystem.
*/

USE ProjectAirbnb;

-- Let's start out by retrieving a list of all the cities in the dataset, while handling NULL values.

SELECT DISTINCT
    COALESCE(city, 'Unknown') AS city
FROM
    property_details
ORDER BY city;


/*
The query shows us that we will be retrieving data from the following 10 cities:
Bangkok, Cape Town, Hong Kong, Istanbul, Mexico City, New York, Paris, Rio, Rome, and Sydney.

How do these cities rank in average price USD per night, cheapest to most expensive?
*/

SELECT
	COALESCE(RANK() OVER(ORDER BY AVG(p.price * e.exchange_rate)), 'Unknown') AS price_rank,
    p.city,
    COALESCE(ROUND(AVG(p.price * e.exchange_rate), 2), 'Unknown') AS average_price_usd
FROM
	property_details p
		JOIN
	exchange_rates e ON p.city = e.city
GROUP BY p.city;

/*
Among the ten destinations, Istanbul is the most affordable city for Airbnb rentals, with an average
price of around $19 per night. Istanbul is nearly three times cheaper than any other city, making it a 
great choice for budget-conscious travelers. On the other hand, Rio de Janeiro, New York, and Sydney 
represent the more expensive options, with prices exceeding $140 per night. Rome and Paris, both
situated in the EU, share similar rental rates, probably due to their alignment in the European market
at around $115.

Moving on to property types, while the market offers a diverse range of property types, our next query
will focus on the three most common types of property in each city.
*/

WITH ranked_property_types AS (
	SELECT
		p.city,
        COALESCE(p.property_type, 'Unknown') AS property_type,
		COALESCE(ROUND(AVG(p.price * e.exchange_rate), 2), 'Unknown') AS average_price_usd,
        ROW_NUMBER() OVER(PARTITION BY p.city ORDER BY COUNT(*) DESC) AS property_type_rank
	FROM
		property_details p
			JOIN
		exchange_rates e ON p.city = e.city
	GROUP BY 
		p.city, p.property_type
)
SELECT
	city,
    property_type,
    average_price_usd
FROM
	ranked_property_types
WHERE
	property_type_rank IN (1, 2, 3);

/*
The analysis reveals insights into the prevalent property types across these cities. Entire apartments are
the most popular choice in all the cities but one, Hong Kong has private rooms in apartments taking the lead.
This uniqueness is probably due to Hong Kong's compact living spaces and it's business traveler influx,
distinguishing it from the leisure-focused cities on the list.

Across the board, renting a room is notably more affordable than an entire property, except in Istanbul,
where the presence of rooms in boutique hotels challenges this. Istanbul's historic boutique hotels,
like the Pera Palace Hotel, designed by renowned architect Alexander Vallaury in 1895, provides a unique
and personal experience, justifying the price discrepancy. These rooms will cost you more than renting out
an entire property in Istanbul.

Overall, the data emphasizes a higher demand for entire property listings, indicating more promising booking
prospects for hosts.

Let's see the average price difference between renting out an entire property or a single room in percent
with the next query.	
*/

SELECT 
    COALESCE(ROUND((AVG(p2.average_price_usd) - AVG(p1.average_price_usd)) / AVG(p1.average_price_usd) * 100, 2), 0) AS price_difference
FROM 
    (
        SELECT 
            AVG(p.price * e.exchange_rate) AS average_price_usd
        FROM 
            property_details p
				JOIN 
            exchange_rates e ON p.city = e.city
        WHERE 
            p.property_type LIKE 'Entire%'
        GROUP BY 
            p.property_type
    ) p1,
    (
        SELECT 
            AVG(p.price * e.exchange_rate) AS average_price_usd
        FROM 
            property_details p
				JOIN 
            exchange_rates e ON p.city = e.city
        WHERE 
            p.property_type LIKE '%Room%'
        GROUP BY 
            p.property_type
    ) p2;

/*
The query result aligns with common sense, with renting a room being approximately 42% cheaper on 
average when compared to leasing an entire property. This means that entire properties are over 98% more
expensive in comparison to a room, not only because of space, but also due to their high demand.

Despite the cost difference, the demand for entire properties can be attributed to the tourist-oriented
nature of the cities under examination. These 10 cities are some of the biggest tourists hotspots in
the world, often attracting travelers in groups or families, necessitating the availability of size that
can accommodate larger parties. If you are a host with only has a single room to offer, you will have to
offer a lower price due to the size of your property and naturally you can expect less bookings year-round.

Going back to the distinct case of Hong Kong, where private rooms in apartments are the leading property type,
we can make some assumptions on why the demand is different here. While the city's compactness and business 
environment likely play a role, the popularity of more cost-effective accommodations could be linked to the 
city's reputation as one of the best places to shop in the world. Hong Kong is known for its competitive retail
landscape, so visitors may opt to save on Airbnb costs to allocate more resources to their shopping sprees.

Let's see the two most rare property types in each city, now that we've looked at the popular types.
*/

WITH ranked_property_types AS (
    SELECT 
        p.city, 
		COALESCE(p.property_type, 'Unknown') AS property_type, 
        ROUND(AVG(p.price * e.exchange_rate), 2) AS average_price_usd,
        ROW_NUMBER() OVER(PARTITION BY p.city ORDER BY COUNT(*) ASC) AS type_rank
    FROM 
        property_details p
			JOIN 
        exchange_rates e ON p.city = e.city
    GROUP BY 
        p.city, p.property_type
)
SELECT 
    city, 
    property_type, 
    average_price_usd
FROM 
    ranked_property_types
WHERE 
    type_rank <= 2;

    
/*
The list shows us the two most rare property types in each city.

We can see the renting a rare property type can go two ways: shoot the price up or down.

In Capetown you can rent much cheaper if you can book the rare 'Bus' property where you will be
renting out an immovable bus for stay. In Istanbul and Sydney you can also find a cheap place
to stay in a yurt. Rome's unique property is somewhat similar to Capetown's because you can save
money by sleeping on the sea when renting out an immovable boat.

However, if you are willing to spend more money on your stay in Rome, you can also rent out a room
on an island. This will cost you significantly more, but the experience may be worth it just like
in Bangkok where you cant rent a 'Castle'. Bangkok is known to be home to many historical sites like
temples and palaces, so it is no suprise you can rent a night in one of its colonial age castles.
France is heavily forested, and you can take advantage of this when in Paris by staying in the rare
treehouse property, while in New York and Rio De Janiero you can have a more relaxing vacation by
renting in a resort or vacation home, where there is personal-service accommodating your needs.

It is clear that the uncommon types of properties in each city have benefits. If you own a property
that is unique like the treehouse in Paris, or true to the culture like a castle in Bangkok, renting
out the property to Airbnb guests will be very proftiable, given the fact that just staying in some of these
places is an experience in itself.

You can also become a host through a much cheaper property type by building a yurt yourself for relatively cheap
and renting it out in cities like Sydney and Istanbul where tourists are common so demand for cheap simple places
to stay for the night is high, especially considering we can see that there are not many yurts on the market.

This query exposed that fact that there is some demand for yurts to be rented out on Airbnb, giving a very viable
option to anyone trying to rent out pieces of their property. If you own a large property, in Los Angeles for 
example, you can build a basic yurt on it for starting as low as $10,000 and as long as you follow Los Angeles'
specfic rules regarding short term-rentals and adhere to guidelines while obtaining the necessary permits, you 
can rent it out on Airbnb. For those that want to get into hosting an Airbnb in a city with travelers looking
for a cheap place to sleep, this is a great option to make use of their owned land because it is one of the most
affordable ways to become a host.

Lets quickly look at how people that stayed in Airbnb yurts felt about their experiences through their review scores.

We can compare yurt scores to all the other properties that are not yurts.
*/

SELECT
	'Yurt' AS property_type,
    COALESCE(AVG(overall_rating), 0) AS avg_overall_rating,
    COALESCE(AVG(cleanliness_score), 0) AS avg_cleanliness,
    COALESCE(AVG(location_score), 0) AS avg_location_rating,
    COALESCE(AVG(value_score), 0) AS avg_value,
    COALESCE(AVG(accuracy_score), 0) AS avg_accuracy,
    COALESCE(AVG(communication_score), 0) AS avg_host_communication
FROM
	listing_reviews r
		JOIN
	property_details p ON p.listing_id = r.listing_id
WHERE
	p.property_type LIKE '%Yurt%'
UNION
SELECT
	'All Other' AS property_type,
    COALESCE(AVG(overall_rating), 0) AS avg_overall_rating,
    COALESCE(AVG(cleanliness_score), 0) AS avg_cleanliness,
    COALESCE(AVG(location_score), 0) AS avg_location_rating,
    COALESCE(AVG(value_score), 0) AS avg_value,
    COALESCE(AVG(accuracy_score), 0) AS avg_accuracy,
    COALESCE(AVG(communication_score), 0) AS avg_host_communication
FROM
	listing_reviews lr
WHERE
	lr.listing_id NOT IN (SELECT listing_id FROM property_details WHERE property_type LIKE '%Yurt%');
    

/*
The data shows that yurts generally have scores that are equal to the average ratings for the other 
Airbnb properties, except for their value and location scores.

For property-owners contemplating the construction of a yurt for Airbnb purposes, leveraging this
information can give you a competitive edge. Prioritizing enhancements in value and location can
significantly improve the yurt's overall appeal compared to other options in the market.

Increasing value is as simple as incorporating guest-focused amenities such as entertainment options
like a TV, games, and reading materials, alongside well-stocked supplies like high-quality soaps, towels,
and other essentials. Offering complimentary snacks, modern furnishings, and a tastefully designed
interior while also ensuring optimal insulation for temperature control can elevate the value of a yurt.
These additions should increase value but, listening to guest feedback and implementing their ideas 
for further improvements along with maintaining the yurt's condition is the best way to bring in more value.

Location is a bit more difficult to improve upon because your property is where it is, but a host can still
clean the area around the yurt while placing flowers, pathways, and scenic viewpoints that can upgrade the overall
appeal of the location. Additionally, a host should always provide guests with insights into nearby attractions
and social activities. The guests may think there is nothing to do near the location because they are don't know
where to look, but the host can open their eyes to what the city and its surronding areas have to offer.

Implementing these upgrades not only improves guest satisfaction and review scores but also fosters 
guest loyalty, which will establish a more trusting and enduring relationship with returning visitors.

Considering the presence of diverse property types, including treehouses, castles, entire houses, and resorts,
within the dataset, the comparable ratings of yurts show their viability as an attractive cheap hosting option.
Strategic improvements addressing value and location can position a host's yurt to be one of the best in the area.

Now that we've looked at the reviews for a property type such as a yurt, let's take a look at how each city
compares to one another in review scores to find trends that could provide insights into each city.
*/

SELECT 
    COALESCE(city, 'Unknown') AS city,
    COALESCE(ROUND(AVG(overall_rating), 2), 0) AS avg_overall_rating,
    COALESCE(ROUND(AVG(cleanliness_score), 2), 0) AS avg_cleanliness,
    COALESCE(ROUND(AVG(location_score), 2), 0) AS avg_location_rating,
    COALESCE(ROUND(AVG(value_score), 2), 0) AS avg_value,
    COALESCE(ROUND(AVG(accuracy_score), 2), 0) AS avg_accuracy,
    COALESCE(ROUND(AVG(communication_score), 2), 0) AS avg_host_communication
FROM 
    listing_reviews lr
    RIGHT JOIN property_details pd ON lr.listing_id = pd.listing_id
WHERE 
    overall_rating IS NOT NULL 
    AND cleanliness_score IS NOT NULL 
    AND location_score IS NOT NULL 
    AND value_score IS NOT NULL 
    AND accuracy_score IS NOT NULL 
    AND communication_score IS NOT NULL
GROUP BY 
    city
ORDER BY avg_overall_rating DESC;

/*
From the results we can see that overall Paris is ranked the highest while Hong Kong is at the bottom.
Every city has an overall score of at least 90, except Hong Kong at a low score of 89.

A closer look reveals Hong Kong's cleanliness and accuracy show that this is where the city struggles.
This shows that Airbnbs in Hong Kong do not have the most reliable pictures, and descriptions of the listings
compared to all the other cities while also being less sanitary which is important to note if you plan on
renting an Airbnb in Hong Kong. Later in the project, we will go over how you can avoid unreliable and 
unsanitary listings while visiting Hong Kong through paying a greater price.

This information could be advantageous to a person looking to host in the city. If you can provide value and
keep the place clean you will have a better property than most Airbnbs in the city's market.

When travelling to any city, I personally think that the location is more important than the actual property
you are staying in. This is because we experience what the city has to offer through social activites,
sites, and customs that allow us to live in the culture of the city we are visiting. The score might also 
indicate that the area is safe and the direct location of the property is well-maintained.

Let's order the cities by their average location score.
*/

SELECT
	p.city,
    AVG(location_score) AS avg_location_rating,
	AVG(overall_rating) AS avg_overall_rating,
    AVG(cleanliness_score) AS avg_cleanliness,
    AVG(value_score) AS avg_value,
    AVG(accuracy_score) AS avg_accuracy,
    AVG(communication_score) AS avg_host_communication
FROM
	listing_reviews r
		JOIN
	property_details p ON p.listing_id = r.listing_id
WHERE 
    overall_rating IS NOT NULL 
    AND cleanliness_score IS NOT NULL 
    AND location_score IS NOT NULL 
    AND value_score IS NOT NULL 
    AND accuracy_score IS NOT NULL 
    AND communication_score IS NOT NULL
GROUP BY
	p.city
ORDER BY avg_location_rating DESC;

/*
The result set shows that Mexico City ranks the highest with Rio and Cape Town right behind it. These cities 
have the most to offer when it comes to location leading to hopes of a variety of activites near the listing.
While Mexico City is a very safe place to travel, it is still considered a bit less safe than the rest of the 
cities on this list. Regardless of this, Mexico City boasts the only location score as high as 9.8, showing how
the city has a lot to offer regardless of it slightly worse reputation. It also may reveal that safety does
not play a significant role in this dataset's location score. This makes sense considering all the cities in 
this dataset are very tourist friendly and are considered to be some of the safest cities to travel to, even alone.

Let's now look into how price correlates with the review scores in each city.

Using the price averages we found in the second query, let's compare the average review scores for above average
and below average priced properties in order to see what paying less or more money for an Airbnb leads to.
*/

WITH avg_price AS (
    SELECT 
        p.city,
        AVG(p.price * e.exchange_rate) AS average_price_usd
    FROM 
        property_details p
			JOIN 
        exchange_rates e ON p.city = e.city
    GROUP BY 
        p.city
)
SELECT 
    p.city,
	COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) >= ap.average_price_usd THEN lr.overall_rating END), 0) AS overall_score_above_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) < ap.average_price_usd THEN lr.overall_rating END), 0) AS overall_score_below_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) >= ap.average_price_usd THEN lr.accuracy_score END), 0) AS accuracy_above_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) < ap.average_price_usd THEN lr.accuracy_score END), 0) AS accuracy_below_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) >= ap.average_price_usd THEN lr.cleanliness_score END), 0) AS cleanliness_above_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) < ap.average_price_usd THEN lr.cleanliness_score END), 0) AS cleanliness_below_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) >= ap.average_price_usd THEN lr.communication_score END), 0) AS communication_above_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) < ap.average_price_usd THEN lr.communication_score END), 0) AS communication_below_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) >= ap.average_price_usd THEN lr.location_score END), 0) AS location_above_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) < ap.average_price_usd THEN lr.location_score END), 0) AS location_below_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) >= ap.average_price_usd THEN lr.value_score END), 0) AS value_above_avg,
    COALESCE(AVG(CASE WHEN (p.price * e.exchange_rate) < ap.average_price_usd THEN lr.value_score END), 0) AS value_below_avg
FROM 
    listing_reviews lr
		JOIN 
	property_details p ON p.listing_id = lr.listing_id
		JOIN 
	avg_price ap ON p.city = ap.city
		JOIN 
	exchange_rates e ON p.city = e.city
GROUP BY 
    p.city
ORDER BY overall_score_above_avg DESC;

/*
The result set is suprising because it reveals that lower-priced properties have greater overall ratings across
all cities, except in Bangkok where the two are even and the usual outlier Hong Kong, where higher-priced
listings have significantly better scores.

As mentioned earlier, Hong Kong has the lowest overall rating average and the result set implies it is the 
lower-priced properties dragging the overall down. Lower-priced options in this city tend to have lower accuracy
and cleanliness scores showing that Hong Kong having low average scores in those categories is largely due to
their low-priced listings. For people, who want to rent an Airbnb in Hong Kong, the result set implies that paying
a greater price per night should lead to greater satisfaction with the property.

The trend of higher overall ratings for lower-priced properties was primarily influenced by lower accuracy and
cleanliness scores for high-priced listings, potentially indicating a discrepancy between guests' expectations
and the actual property. The more people pay, the greater their expectations will be. 

Hosts should be sure to avoid overselling their listings and use honest portrayal over exaggerated imagery and
descriptions to avoid people believing the listing was not accurate. Cleanliness is also very important, most
hosts hire a team that takes care of cleaning after each rental. Cleanliness scores may be lower for high-priced
places due to high-priced lisitings being bigger on average, making them harder to clean. It is important that
hosts make sure that the job the cleanup team provides is up to their standards.

Overall, the result set implies that for guests, higher prices do not guarantee a greater Airbnb experience.
For hosts, it is important to note that the higher you set your price, the higher the standards your guests 
will have. This means it's best to set a fair price by looking at the average price for the lisitings with 
the same size, amenities, rooms, services, location, and accomadates in your area.

Let us now look into the competitiveness of Airbnb markets in each city through the amount of listings
along with the price per night and overall review score.
*/
    
    SELECT
    p.city,
    COALESCE(COUNT(*), 0) AS total_listings,
    COALESCE(ROUND(AVG(p.price * e.exchange_rate), 2), 0) AS average_price_usd,
    COALESCE(ROUND(AVG(r.overall_rating), 2), 0) AS average_rating
FROM
    property_details p
        JOIN listing_reviews r ON p.listing_id = r.listing_id
        JOIN exchange_rates e ON p.city = e.city
WHERE 
    r.overall_rating IS NOT NULL 
GROUP BY
    p.city
ORDER BY
    total_listings DESC;


/*
The result set shows that Paris has the most total listing by far at roughly 65,000 and Hong Kong has the least
at around 7000. Paris clearly has the most demand for Airbnb of all the cities, it alone has about the same
amount of listings as Hong Kong, Cape Town, Bangkok, and Mexico City combined, even though it is much smaller 
than all of those cities. The other eight cities have anywhere from 20,000 - 35,000 with New York and Sydney
at the top of that range while, Bangkok and Cape Town are at the bottom of it. 

This shows us that Paris is clearly the most competitve place to host an Airbnb. This competitive Airbnb market
has created some of the best listings in the world. The proof is in Paris boasting the greatest overall rating 
average and their high prices. Listings in Paris are some of the best, so if you plan to host an Airbnb in the city,
the expectations here are far greater than a place like Hong Kong that has the lowest overall ratings.

Hosting an Airbnb in Hong Kong may be a bit easier due to lower competition in your surronding area,
making it easier to become one of the best places to stay in your area. Hosting in Paris, would prove to
be more difficult, but if you can meet the high standards or even go beyond them, there is greater lucrative
oppurtunity because there is clearly more demand for Airbnbs in Paris than other other city by far. 

Now that we have looked at the standards each host should meet according to their city's competitiveness,
let's now look at the additions a host can add to their own profile and how it affects their listing's success.
This information can also reveal what guests should look for in hosts when searching through listings.

Host and guests have the option to add a profile picture and verify their identity. Let's see if the renting
under a host who participates in both of these two can lead to a better experience during the stay.
*/

SELECT 
    CASE 
        WHEN profile_pic = 't' AND identity_verified = 't' THEN 'Both Verified' 
        ELSE 'Not Verified' 
    END AS verification_status,
	COALESCE(AVG(overall_rating), 0) AS avg_overall_rating,
    COALESCE(AVG(cleanliness_score), 0) AS avg_cleanliness,
    COALESCE(AVG(location_score), 0) AS avg_location_rating,
    COALESCE(AVG(value_score), 0) AS avg_value,
    COALESCE(AVG(accuracy_score), 0) AS avg_accuracy,
    COALESCE(AVG(communication_score), 0) AS avg_host_communication
FROM 
    host_information h
		JOIN
    listing_reviews l ON h.host_id = l.host_id
GROUP BY 
    verification_status;

/*
The results set reveals that if a host does not have their identity verified and a profile picture it is 
not something to worry about when searching listings. In fact, people who are not verified average a rating
of 95, with verified people averaging around 90. Non-Verified hosts also score higher in cleanliness at 9.8
against 9.4 from the verified.

It is possible that this is due to expectations and setting higher standards as mentioned earlier. Regardless,
we now know one who is seeking a good host does not need to worry if they are not verified and do not have a
profile picture as it does not seem to affect ratings.
*/

/*
In conclusion, this Airbnb data analysis shines light on key factors influencing the rental experience in
popular travel destinations. We uncovered the significance of property accuracy and cleanliness for guest 
satisfaction, emphasizing the need for hosts to maintain transparency and cleanliness. We also looked into
options for aspiring hosts depending on their property type and resources.

Additionally, we highlighted the pivotal role of location in shaping a guest's overall experience. Our findings
also underscored the varying competitiveness of Airbnb markets across different cities, prompting hosts to 
differentiate themselves in each unique market through focusing on what each market is lacking.

Lastly, we discovered that while verified host profiles can offer reassurance, the absence of verification doesn't
necessarily hinder a positive stay. What truly matters is the upkeep and honesty of the rental space. This project
demonstrates and practices my proficiency in leveraging data to provide actionable insights for both hosts and 
guests exploring the realm of Airbnb.

Thank you for reading.
*/
