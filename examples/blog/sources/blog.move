// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

// <autogenerated>
//   This file was generated by dddappp code generator.
//   Any changes made to this file manually will be lost next time the file is regenerated.
// </autogenerated>

module rooch_examples::blog {
    use moveos_std::event;
    use moveos_std::object_id::ObjectID;
    use moveos_std::object::Object;
    use moveos_std::context::{Self, Context};
    use moveos_std::table::{Self, Table};
    use std::signer;
    use std::string::String;
    use rooch_examples::article::Article;

    friend rooch_examples::blog_add_article_logic;
    friend rooch_examples::blog_remove_article_logic;
    friend rooch_examples::blog_create_logic;
    friend rooch_examples::blog_update_logic;
    friend rooch_examples::blog_delete_logic;
    friend rooch_examples::blog_aggregate;

    const ErrorDataTooLong: u64 = 102;
    const ErrorInappropriateVersion: u64 = 103;
    const ErrorNotGenesisAccount: u64 = 105;

    struct Blog has key, store {
        version: u64,
        name: String,
        articles: Table<ObjectID, Object<Article>>,
    }

    public fun version(blog: &Blog): u64 {
        blog.version
    }

    public fun name(blog: &Blog): String {
        blog.name
    }

    public(friend) fun set_name(blog: &mut Blog, name: String) {
        assert!(std::string::length(&name) <= 200, ErrorDataTooLong);
        blog.name = name;
    }

    public fun articles(blog: &Blog): &Table<ObjectID, Object<Article>> {
        &blog.articles
    }

    public fun articles_mut(blog: &mut Blog): &mut Table<ObjectID, Object<Article>> {
        &mut blog.articles
    }

    public(friend) fun new_blog(
        name: String,
        articles: Table<ObjectID, Object<Article>>,
    ): Blog {
        assert!(std::string::length(&name) <= 200, ErrorDataTooLong);
        Blog {
            version: 0,
            name,
            articles,
        }
    }

    struct ArticleAddedToBlog has drop {
        version: u64,
        article_id: ObjectID,
    }

    public fun article_added_to_blog_article_id(article_added_to_blog: &ArticleAddedToBlog): ObjectID {
        article_added_to_blog.article_id
    }

    public(friend) fun new_article_added_to_blog(
        blog: &Blog,
        article_id: ObjectID,
    ): ArticleAddedToBlog {
        ArticleAddedToBlog {
            version: version(blog),
            article_id,
        }
    }

    struct ArticleRemovedFromBlog has drop {
        version: u64,
        article_id: ObjectID,
    }

    public fun article_removed_from_blog_article_id(article_removed_from_blog: &ArticleRemovedFromBlog): ObjectID {
        article_removed_from_blog.article_id
    }

    public(friend) fun new_article_removed_from_blog(
        blog: &Blog,
        article_id: ObjectID,
    ): ArticleRemovedFromBlog {
        ArticleRemovedFromBlog {
            version: version(blog),
            article_id,
        }
    }

    struct BlogCreated has drop {
        name: String,
    }

    public fun blog_created_name(blog_created: &BlogCreated): String {
        blog_created.name
    }

    public(friend) fun new_blog_created(
        name: String,
    ): BlogCreated {
        BlogCreated {
            name,
        }
    }

    struct BlogUpdated has drop {
        version: u64,
        name: String,
    }

    public fun blog_updated_name(blog_updated: &BlogUpdated): String {
        blog_updated.name
    }

    public(friend) fun new_blog_updated(
        blog: &Blog,
        name: String,
    ): BlogUpdated {
        BlogUpdated {
            version: version(blog),
            name,
        }
    }

    struct BlogDeleted has drop {
        version: u64,
    }

    public(friend) fun new_blog_deleted(
        blog: &Blog,
    ): BlogDeleted {
        BlogDeleted {
            version: version(blog),
        }
    }


    public(friend) fun update_version_and_add(ctx: &mut Context, account: &signer, blog: Blog) {
        assert!(signer::address_of(account) == @rooch_examples, ErrorNotGenesisAccount);
        blog.version = blog.version + 1;
        private_add_blog(ctx, account, blog);
    }

    public(friend) fun remove_blog(ctx: &mut Context): Blog {
        context::move_resource_from<Blog>(ctx, @rooch_examples)
    }

    public(friend) fun add_blog(ctx: &mut Context, account: &signer, blog: Blog) {
        assert!(signer::address_of(account) == @rooch_examples, ErrorNotGenesisAccount);
        assert!(blog.version == 0, ErrorInappropriateVersion);
        private_add_blog(ctx, account, blog);
    }

    fun private_add_blog(ctx: &mut Context, account: &signer, blog: Blog) {
        assert!(std::string::length(&blog.name) <= 200, ErrorDataTooLong);
        context::move_resource_to(ctx, account, blog);
    }

    public(friend) fun drop_blog(blog: Blog) {
        let Blog {
            version: _version,
            name: _name,
            articles,
        } = blog;
        table::destroy_empty(articles);
    }

    public(friend) fun borrow_mut_blog(ctx: &mut Context): &mut Blog {
        context::borrow_mut_resource<Blog>(ctx, @rooch_examples)
    }

    public fun borrow_blog(ctx: &mut Context): &Blog {
        context::borrow_resource<Blog>(ctx, @rooch_examples)
    }

    public(friend) fun update_version(blog: &mut Blog) {
        blog.version = blog.version + 1;
    }

    public(friend) fun emit_article_added_to_blog(article_added_to_blog: ArticleAddedToBlog) {
        event::emit(article_added_to_blog);
    }

    public(friend) fun emit_article_removed_from_blog(article_removed_from_blog: ArticleRemovedFromBlog) {
        event::emit(article_removed_from_blog);
    }

    public(friend) fun emit_blog_created(blog_created: BlogCreated) {
        event::emit(blog_created);
    }

    public(friend) fun emit_blog_updated(blog_updated: BlogUpdated) {
        event::emit(blog_updated);
    }

    public(friend) fun emit_blog_deleted(blog_deleted: BlogDeleted) {
        event::emit(blog_deleted);
    }

}
