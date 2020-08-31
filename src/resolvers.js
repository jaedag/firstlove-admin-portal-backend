const resolvers = {
	Mutation: {
		/* NEW USER */
		AddMember: async (obj, params, ctx, resolveInfo) => {
			params.email = await bcryptjs.hash(params.email, 10);
			const findUser = await ctx.driver.session().run(`MATCH (m:Member {email: "${params.email}"}) return m`);
			if (findUser.records.length > 0) {
				throw new ApolloError('This user already exists', 200, [ 'user_already_exists' ]);
				return 'This user already exists';
			}
			return neo4jgraphql(obj, params, ctx, resolveInfo, true);
		}
	}
};
